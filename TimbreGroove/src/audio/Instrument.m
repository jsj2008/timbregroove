//
//  Instrument.m
//  TimbreGroove
//
//  Created by victor on 2/28/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Instrument.h"
#import "Config.h"
#import "SoundSystem.h"

@interface Instrument () {
    MIDITimeStamp   _prevTimeStamp;
    AUGraph         _graph;
}

@end
@implementation Instrument

+(id)instrumentWithConfig:(ConfigInstrument *)config
                 andGraph:(AUGraph)graph
{
    return [[Instrument alloc] initWithConfig:config andGraph:graph];
}


-(id)initWithConfig:(ConfigInstrument *)config
           andGraph:(AUGraph)graph
{
    if( (self = [super init]) )
    {
        _graph = graph;
        [self makeSampler];
        [self loadSound:config];
        _lowestPlayable = config.low;
        _highestPlayable = config.high;
        _prevTimeStamp = 0;
    }
    
    return self;
}

-(void)dealloc
{
    if( _midiEndPoint )
        CheckError(MIDIEndpointDispose(_midiEndPoint), "Error disposing endpoint");

    // "Calling this function deallocates the audio unit’s resources."
    // AND CRASHES THE APP
  //  AudioUnitUninitialize(_sampler);
    TGLog(LLJustSayin, @"Instrument gone");
}

-(void)loadSound:(ConfigInstrument *)config
{
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
    
    result = AUGraphNodeInfo (_graph, _graphNode, 0, &_sampler);
    CheckError(result,"Unable to obtain a reference to the Sampler unit.");
    
    TGLog(LLJustSayin, @"Created sampler: %ld",(long)_sampler);
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

@end
