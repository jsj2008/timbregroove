//
//  Instrument.m
//  TimbreGroove
//
//  Created by victor on 2/28/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Sampler.h"
#import "Config.h"
#import "SoundSystem.h"
#import "Midi.h"
#import "Names.h"
#import "Parameter.h"

@interface Sampler () {
    SoundSystem *      _ss;
    AUGraph            _graph;
    Midi *             _midi;
    id                 _myBlock;
    
    NSURL *             _presetURL;
    bool                _isSoundFont;
    int                 _patch;
}
@property (nonatomic,strong) NSString * name;
@end

@implementation Sampler

+(id)samplerWithSoundSystem:(SoundSystem *)ss;
{
    return [[Sampler alloc] initWithSoundSystem:ss];
}


-(id)initWithSoundSystem:(SoundSystem *)ss
{
    if( (self = [super init]) )
    {
        _ss = ss;
        _graph = ss.processGraph;
    }    
    return self;
}

#if DEBUG
-(void)dealloc
{
    TGLog(LLObjLifetime, @"%@ released",self);
}
#endif

-(void)loadSound:(ConfigInstrument *)config midi:(Midi *)midi
{
    _midi = midi;
    _isSoundFont = config.isSoundFont;
    NSString * ext = _isSoundFont ? @"sf2" : @"aupreset";
    
    _presetURL = [[NSBundle mainBundle] URLForResource: config.preset
                                         withExtension: ext];
    
    NSAssert(_presetURL, @"preset path fail: %@",config.preset);

    _patch           = config.patch;
    _lowestPlayable  = config.low;
    _highestPlayable = config.high;
        
    [self reloadSound];
}

-(void)reloadSound
{
    if( !_graphNode )
        [self makeAUNode];
    if( !_sampler )
        [self makeAudioUnit];
        
    if( _isSoundFont )
        [self loadSF2FromURL:_presetURL withPatch:_patch];
    else
        [self loadSynthFromPresetURL: _presetURL];
    
    TGLog(LLAudioResource, @"Loaded sound %s for %@", _isSoundFont ? "SoundFont" : "AUPreset" ,self.name);
}

-(void)didAttachToGraph:(SoundSystem *)ss
{
    if( !_sampler )
        [self reloadSound];
    [ss plugInstrumentIntoBus:self];
    [_midi makeDestination:self];
}

-(void)didDetachFromGraph:(SoundSystem *)ss
{
    [_midi releaseDestination:self];
    [ss unplugInstrumentFromBus:self];
    CheckError( AudioUnitUninitialize(_sampler), "Failed to UN-initialize AU" );
    _graphNode = 0;
    _sampler = 0;
    _myBlock = nil;
}

-(void)makeAUNode
{
    OSStatus result = noErr;
    
    AudioComponentDescription cd = {};
    cd.componentManufacturer     = kAudioUnitManufacturer_Apple;
    cd.componentFlags            = 0;
    cd.componentFlagsMask        = 0;
    cd.componentType = kAudioUnitType_MusicDevice;
    cd.componentSubType = kAudioUnitSubType_Sampler;
    
    result = AUGraphAddNode(_graph, &cd, &_graphNode);
    CheckError(result,"Unable to add the Sampler unit to the audio processing graph.");
}

-(void)makeAudioUnit
{
    OSStatus result = AUGraphNodeInfo (_graph, _graphNode, 0, &_sampler);
    CheckError(result,"Unable to obtain a reference to the Sampler unit.");
    TGLog(LLAudioResource, @"Created sampler AU: %p for %@",(void *)_sampler, _name );
    [_ss configUnit:_sampler];
    CheckError( AudioUnitInitialize(_sampler), "Failed to initialize" );
}

- (OSStatus) loadSynthFromPresetURL: (NSURL *) presetURL
{
    OSStatus result = noErr;
    
    NSDictionary * presetPropertyList = [NSDictionary dictionaryWithContentsOfURL:presetURL];
    
    if (presetPropertyList != 0) {
        
        CFPropertyListRef plr = (__bridge CFPropertyListRef)presetPropertyList;
        result = AudioUnitSetProperty(
                                      _sampler,
                                      kAudioUnitProperty_ClassInfo,
                                      kAudioUnitScope_Global,
                                      0,
                                      &plr,
                                      sizeof(plr)
                                      );
        CheckError(result, "Unable to set the patch on a soundfont file");
    }

    return result;
}

-(OSStatus) loadSF2FromURL: (NSURL *)bankURL
                 withPatch: (int)presetNumber
{
    OSStatus result = noErr;
    
    AUSamplerBankPresetData bpdata;
    bpdata.bankURL  = (__bridge CFURLRef) bankURL;
    bpdata.bankMSB  = kAUSampler_DefaultMelodicBankMSB;
    bpdata.bankLSB  = kAUSampler_DefaultBankLSB;
    bpdata.presetID = (UInt8) presetNumber;
    
    result = AudioUnitSetProperty(_sampler,
                                  kAUSamplerProperty_LoadPresetFromBank,
                                  kAudioUnitScope_Global,
                                  0,
                                  &bpdata,
                                  sizeof(bpdata));
    CheckError(result, "Unable to set the preset property on the Sampler.");
    return result;
}

-(MIDISendBlock)callback
{
    if( !_myBlock )
    {
        AudioUnit au = _sampler; // avoid capturing 'self' in block
        _myBlock = [^ OSStatus( UInt32 inStatus, UInt32 inData1, UInt32 inData2, UInt32 inOffsetSampleFrame) {
            return MusicDeviceMIDIEvent( au, inStatus, inData1, inData2, inOffsetSampleFrame);
        } copy];
    }
    return _myBlock;
}

-(void)handleParamChange:(int)param value:(float)value
{
    
}

-(void)changePitch:(float)f
{
    
}

-(void)getParameters:(NSMutableDictionary *)parameters
{
    FloatParamBlock(^NOOP_closure)(int) =
    ^FloatParamBlock(int param){
        return ^(float f) {
            [self handleParamChange:param value:f ];
        };
    };

    NSString * nameEx = [@"_" stringByAppendingString:self.name];
    
#define PARAMEX(k) [k stringByAppendingString:nameEx]
    
    [parameters addEntriesFromDictionary:
     @{
             PARAMEX(kParamPitch): [Parameter withBlock:^(float f){ [self changePitch:f]; }],
      PARAMEX(kParamInstrumentP1): [Parameter withBlock:[NOOP_closure(1) copy]],
      PARAMEX(kParamInstrumentP2): [Parameter withBlock:[NOOP_closure(2) copy]],
      PARAMEX(kParamInstrumentP3): [Parameter withBlock:[NOOP_closure(3) copy]],
      PARAMEX(kParamInstrumentP4): [Parameter withBlock:[NOOP_closure(4) copy]],
      PARAMEX(kParamInstrumentP5): [Parameter withBlock:[NOOP_closure(5) copy]],
      PARAMEX(kParamInstrumentP6): [Parameter withBlock:[NOOP_closure(6) copy]],
      PARAMEX(kParamInstrumentP7): [Parameter withBlock:[NOOP_closure(7) copy]],
      PARAMEX(kParamInstrumentP8): [Parameter withBlock:[NOOP_closure(8) copy]],
     }];
}
@end
