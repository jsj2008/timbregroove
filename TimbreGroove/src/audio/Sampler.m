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

@interface Sampler () {
    AUGraph       _graph;
     Midi * _midi;
    id _myBlock;
}
@property (nonatomic,strong) NSString * name;
@end
@implementation Sampler

+(id)samplerWithAUGraph:(AUGraph)graph
{
    return [[Sampler alloc] initWithAUGraph:graph];
}


-(id)initWithAUGraph:(AUGraph)graph
{
    if( (self = [super init]) )
    {
        _graph = graph;
        [self makeSampler];
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
    
    bool isSoundfont = config.isSoundFont;
    NSString * ext = isSoundfont ? @"sf2" : @"aupreset";
    
    NSURL *presetURL = [[NSBundle mainBundle] URLForResource: config.preset
                                               withExtension: ext];
    
    NSAssert(presetURL, @"preset path fail: %@",config.preset);
    
    if( isSoundfont )
    {
        [self loadSF2FromURL:presetURL withPatch:config.patch];
    }
    else
    {
        [self loadSynthFromPresetURL: presetURL];
    }
    
    _lowestPlayable = config.low;
    _highestPlayable = config.high;
    
    TGLog(LLAudioResource, @"Loaded sound of type %@",ext);
}

-(void)didAttachToGraph:(SoundSystem *)ss
{
    AudioUnitInitialize(_sampler);
    [_midi makeDestination:self];
    [ss plugInstrumentIntoBus:self];
}

-(void)didDetachFromGraph:(SoundSystem *)ss
{
    [ss unplugInstrumentFromBus:self];
    [_midi releaseDestination:self];
    AudioUnitUninitialize(_sampler);
}

-(void)makeSampler
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

-(void)instantiateAU
{
    OSStatus result = AUGraphNodeInfo (_graph, _graphNode, 0, &_sampler);
    CheckError(result,"Unable to obtain a reference to the Sampler unit.");
    TGLog(LLAudioResource, @"Created sampler AU: %p",(void *)_sampler);
    AudioUnit sampler = _sampler;
    _myBlock = [^ OSStatus( UInt32 inStatus, UInt32 inData1, UInt32 inData2, UInt32 inOffsetSampleFrame) {
        return MusicDeviceMIDIEvent( sampler, inStatus, inData1, inData2, inOffsetSampleFrame);
    } copy];
    
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
    return _myBlock;
}

@end
