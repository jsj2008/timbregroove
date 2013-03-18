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
    AUGraph         _graph;
}

@end
@implementation Sampler

+(id)instrumentWithConfig:(ConfigInstrument *)config
                 andGraph:(AUGraph)graph
{
    return [[Sampler alloc] initWithConfig:config andGraph:graph];
}


-(id)initWithGraph:(AUGraph)graph
{
    if( (self = [super init]) )
    {
        _graph = graph;
        _available = true;
        [self makeSampler];
    }
    
    return self;
}
-(id)initWithConfig:(ConfigInstrument *)config
           andGraph:(AUGraph)graph
{
    if( (self = [super init]) )
    {
        _graph = graph;
        [self makeSampler];
        [self loadSound:config];
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
    TGLog(LLObjLifetime, @"Instrument gone");
}

-(void)releaseSound
{
    _available = true;
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
    _lowestPlayable = config.low;
    _highestPlayable = config.high;
    _available = false;
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

-(void)setNodeIntoGraph
{
    OSStatus result = AUGraphNodeInfo (_graph, _graphNode, 0, &_sampler);
    CheckError(result,"Unable to obtain a reference to the Sampler unit.");
    TGLog(LLMidiStuff, @"Created sampler: %ld",(long)_sampler);
}

-(void)setupMidi:(Midi *)midi
{
    OSStatus result = noErr;
    
    result = MIDIOutputPortCreate (midi.midiClient, CFSTR("out port"), &_outPort );

    CheckError(result, " Couldn't create MIDI output port");
    
    MIDIEndpointRef virtualEndpoint;
    
    result = MIDIDestinationCreate(midi.midiClient,
                                   CFSTR("TG Virtual Destination"),
                                   midi.readProc,
                                   (void *)(_sampler),
                                   &virtualEndpoint);
    
    CheckError(result,"MIDIDestinationCreate failed");
    
    _midiEndPoint = virtualEndpoint;
}

-(void)sendNote:(MIDINoteMessage *)noteMsg
{
    __block MIDIPacketList packetList;
    packetList.numPackets = 1;
    packetList.packet[ 0]. length = 3;
    packetList.packet[ 0]. data[ 0] = 0x90;
    packetList.packet[ 0]. data[ 1] = noteMsg->note & 0x7F;
    packetList.packet[ 0]. data[ 2] = noteMsg->velocity & 0x7F;
    packetList.packet[ 0]. timeStamp = 0;
  
/*
    OSStatus
	result = MusicDeviceMIDIEvent(_sampler, 0x90, noteMsg->note & 0x7,  noteMsg->velocity & 0x7F, 0);
    CheckError(result, "Couldn't send note directly to sampler");
    
    [NSObject performBlock:[^{
        OSStatus
        result = MusicDeviceMIDIEvent(_sampler, 0x80, noteMsg->note & 0x7,  0, 0);
    } copy] afterDelay:noteMsg->duration];

*/
    CheckError( MIDISend(_outPort, _midiEndPoint, &packetList), "Couldn't send note ON");
 
    [NSObject performBlock:[^{
        packetList.packet[ 0]. data[ 0] = 0x80;
        CheckError( MIDISend(_outPort, _midiEndPoint, &packetList), "Couldn't send note OFF");
    } copy] afterDelay:noteMsg->duration];

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
