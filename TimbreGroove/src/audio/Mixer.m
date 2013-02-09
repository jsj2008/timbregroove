//
//  Mixer.m
//  TimbreGroove
//
//  Created by victor on 1/27/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Mixer.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "Config.h"
#import "Mixer+Diag.h"

#ifndef DEBUG
#undef NSAssert
#define NSAssert(cond,str,...)
#endif

static inline const char * fixOSResult(OSStatus result)
{
    static char resultString[10];
    sprintf(resultString, "%08lx",result);
    /*
    UInt32 swappedResult = CFSwapInt32HostToBig (result);
    bcopy (&swappedResult, resultString, 4);
    resultString[4] = '\0';
     */
    return resultString;
}

enum MidiNotes {
    kC0 = 0,
    kC1 = 12,
    kC2 = 24,
    kC3 = 36,
    kC4 = 48,
    kC5 = 60,
    kMiddleC = kC5,
    kA440 = 69,
    kC6 = 72,
    kC7 = 84,
    };

enum {
	kMIDIMessage_NoteOn    = 0x9,
	kMIDIMessage_NoteOff   = 0x8,
};

static Mixer * __sharedMixer;

@interface Sound () {
    AudioUnit _samplerUnit;
}

@end
@implementation Sound

-(id)initWithAudioUnit:(AudioUnit)au andMeta:(NSDictionary *)meta
{
    if( (self = [super init]) )
    {
        _samplerUnit = au;
        _lowestPlayable = [meta[@"lo"] intValue];
        _highestPlayable = [meta[@"hi"] intValue];
    }
    
    return self;
}

-(OSStatus)playNote:(int)note forDuration:(NSTimeInterval)duration
{
	UInt32 noteNum = note;
	UInt32 onVelocity = 127;
	UInt32 noteCommand = 	kMIDIMessage_NoteOn << 4 | 0;
    
    OSStatus result = noErr;
    result = MusicDeviceMIDIEvent (_samplerUnit,
                                   noteCommand,
                                   noteNum, onVelocity, 0);
    
    NSAssert(result == noErr,@"Unable to start note. Error code: %d '%s'\n", (int) result, fixOSResult(result));
    [self performSelector:@selector(stopNote:) withObject:@(note) afterDelay:duration];
    return result;
}

-(OSStatus)stopNote:(NSNumber *)note
{
	UInt32 noteNum = [note unsignedIntegerValue];
	UInt32 noteCommand = kMIDIMessage_NoteOff << 4 | 0;
    
    OSStatus result = noErr;
    result = MusicDeviceMIDIEvent (_samplerUnit,
                                   noteCommand,
                                   noteNum, 0, 0);
    
    NSAssert(result == noErr,@"Unable to stop note. Error code: %d '%s'\n", (int) result, fixOSResult(result));
    return result;
}

@end


//..............................................................................
//..............................................................................
//..............................................................................

@interface Mixer () {
    AUGraph           _processingGraph;
    NSDictionary *   _aliases;
    Float64          _graphSampleRate;
    NSMutableArray * _samplerUnits;
    AudioUnit        _ioUnit;
    AudioUnit        _mixerUnit;
    AUNode           _mixerNode;
}
@end

@implementation Mixer

-(id)init
{
    self = [super init];
    if( self )
    {
        _samplerUnits = [NSMutableArray new];
        _aliases = [[Config sharedInstance] valueForKey:@"sounds"];
        [self setupAVSession];
        [self setupAUGraph];
        [self configureAndStartAudioProcessingGraph:_processingGraph];
    }
    return self;
}

+(Mixer *)sharedInstance
{
    @synchronized (self) {
        if( !__sharedMixer )
            __sharedMixer = [Mixer new];
    }
    return __sharedMixer;
}

- (void) setMixerOutputGain: (AudioUnitParameterValue) newGain
{    
    OSStatus result = AudioUnitSetParameter (
                                             _mixerUnit,
                                             kMultiChannelMixerParam_Volume,
                                             kAudioUnitScope_Output,
                                             0,
                                             newGain,
                                             0
                                             );
    
    NSAssert (result == noErr, @"Unable to set output gain. Error code: %d '%s'", (int) result, fixOSResult(result));
    
}

-(NSArray *)getAllSoundNames
{
    return [_aliases allKeys];
}

-(Sound *)getSound:(NSString *)name
{
    AudioUnit sampler = [self makeSampler];
    Sound * sound =  [[Sound alloc] initWithAudioUnit:sampler
                                    andMeta:[self loadSound:name sampler:sampler]];
    [_samplerUnits addObject:sound];
    return sound;
}

-(NSDictionary *)loadSound:(NSString *)alias sampler:(AudioUnit)sampler
{
    NSDictionary * meta = _aliases[alias];
    BOOL isSoundfont = [meta[@"isSoundfont"] boolValue];
    NSString * ext = isSoundfont ? @"sf2" : @"aupreset";
    
	NSURL *presetURL = [[NSBundle mainBundle] URLForResource: meta[@"preset"]
                                               withExtension: ext];
    
    NSAssert(presetURL, @"preset path fail: %@",alias);
    
    if( isSoundfont )
    {
        [self loadSF2FromURL:presetURL withPatch:[meta[@"patch"] intValue] sampler:sampler];
    }
    else
    {
        [self loadSynthFromPresetURL: presetURL sampler:sampler];
    }
    
    return meta;
}


-(BOOL)setupAVSession
{
    AVAudioSession *mySession = [AVAudioSession sharedInstance];

    // FIX**************************
 //   [mySession setDelegate: self];

    NSError *audioSessionError = nil;
    [mySession setCategory: AVAudioSessionCategoryPlayback error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error setting audio session category."); return NO;}
    
    _graphSampleRate = 44100.0;
    
    [mySession setPreferredSampleRate: _graphSampleRate error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error setting preferred hardware sample rate."); return NO;}
    
    [mySession setActive: YES error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error activating the audio session."); return NO;}
    
    _graphSampleRate = mySession.sampleRate;
    
    return YES;
}


-(AudioUnit)makeSampler
{
	OSStatus result = noErr;
    
	AudioComponentDescription cd = {};
	cd.componentManufacturer     = kAudioUnitManufacturer_Apple;
	cd.componentFlags            = 0;
	cd.componentFlagsMask        = 0;
	cd.componentType = kAudioUnitType_MusicDevice;
	cd.componentSubType = kAudioUnitSubType_Sampler;
	
    AUNode samplerNode;
    result = AUGraphAddNode(_processingGraph, &cd, &samplerNode);
    NSAssert (result == noErr, @"Unable to add the Sampler unit to the audio processing graph. Error code: %d '%s'", (int) result, fixOSResult(result));

    AudioUnit samplerUnit;
    result = AUGraphNodeInfo (_processingGraph, samplerNode, 0, &samplerUnit);
    NSAssert (result == noErr, @"Unable to obtain a reference to the Sampler unit. Error code: %d '%s'", (int) result, fixOSResult(result));
   
    UInt32 busCount = [_samplerUnits count] + 1;
    result = AudioUnitSetProperty (_mixerUnit,
                                   kAudioUnitProperty_ElementCount,
                                   kAudioUnitScope_Input,
                                   0,
                                   &busCount,
                                   sizeof (busCount)
                                   );
    NSAssert (result == noErr, @"Unable to set buscount on mixer. Error code: %d '%s'", (int) result, fixOSResult(result));
    
    result = AUGraphConnectNodeInput (_processingGraph, samplerNode, 0, _mixerNode, busCount-1);
    NSAssert (result == noErr, @"Unable to interconnect the nodes in the audio processing graph. Error code: %d '%s'", (int) result, fixOSResult(result));
    
    [self configUnit:samplerUnit];
    
    Boolean isUpdated;
    result = AUGraphUpdate(_processingGraph, &isUpdated);
    NSAssert (result == noErr, @"Unable to update graph. Error code: %d '%s'", (int) result, fixOSResult(result));
    
    [self dumpParameters:samplerUnit];
    
    return samplerUnit;
}

-(OSStatus)setupAUGraph
{
	OSStatus result = noErr;
	AUNode ioNode;
    
    // Specify the common portion of an audio unit's identify, used for both audio units
    // in the graph.
	AudioComponentDescription cd = {};
	cd.componentManufacturer     = kAudioUnitManufacturer_Apple;
	cd.componentFlags            = 0;
	cd.componentFlagsMask        = 0;
    
	result = NewAUGraph (&_processingGraph);
    NSAssert (result == noErr, @"Unable to create an AUGraph object. Error code: %d '%s'", (int) result, fixOSResult(result));
    
    // ------ MIXER --------------
    
    cd.componentType          = kAudioUnitType_Mixer;
    cd.componentSubType       = kAudioUnitSubType_MultiChannelMixer;

    result = AUGraphAddNode (_processingGraph, &cd, &_mixerNode);
    NSAssert (result == noErr, @"Unable to add the Mixer unit to the audio processing graph. Error code: %d '%s'", (int) result, fixOSResult(result));

    // ------ I/O --------------
	cd.componentType = kAudioUnitType_Output;
	cd.componentSubType = kAudioUnitSubType_RemoteIO;
    
	result = AUGraphAddNode (_processingGraph, &cd, &ioNode);
    NSAssert (result == noErr, @"Unable to add the Output unit to the audio processing graph. Error code: %d '%s'", (int) result, fixOSResult(result));
    
    
	result = AUGraphOpen (_processingGraph);
    NSAssert (result == noErr, @"Unable to open the audio processing graph. Error code: %d '%s'", (int) result, fixOSResult(result));

	result = AUGraphNodeInfo (_processingGraph, _mixerNode, 0, &_mixerUnit);
    NSAssert (result == noErr, @"Unable to obtain a reference to the I/O unit. Error code: %d '%s'", (int) result, fixOSResult(result));
    
	result = AUGraphNodeInfo (_processingGraph, ioNode, 0, &_ioUnit);
    NSAssert (result == noErr, @"Unable to obtain a reference to the I/O unit. Error code: %d '%s'", (int) result, fixOSResult(result));

    
    UInt32 busCount = 1;
    result = AudioUnitSetProperty (
                                   _mixerUnit,
                                   kAudioUnitProperty_ElementCount,
                                   kAudioUnitScope_Input,
                                   0,
                                   &busCount,
                                   sizeof (busCount)
                                   );
    NSAssert (result == noErr, @"Unable to set buscount on mixer. Error code: %d '%s'", (int) result, fixOSResult(result));
    
	result = AUGraphConnectNodeInput (_processingGraph, _mixerNode, 0, ioNode, 0);
    NSAssert (result == noErr, @"Unable to interconnect the nodes in the audio processing graph. Error code: %d '%s'", (int) result, fixOSResult(result));
    
    
    return result;
}

- (OSStatus) loadSynthFromPresetURL: (NSURL *) presetURL sampler:(AudioUnit)sampler
{
    
	OSStatus result = noErr;
    
    NSDictionary * presetPropertyList = [NSDictionary dictionaryWithContentsOfURL:presetURL];
    
	if (presetPropertyList != 0) {
		
        CFPropertyListRef plr = (__bridge CFPropertyListRef)presetPropertyList;
		result = AudioUnitSetProperty(
                                      sampler,
                                      kAudioUnitProperty_ClassInfo,
                                      kAudioUnitScope_Global,
                                      0,
                                      &plr,
                                      sizeof(plr)
                                      );
        NSAssert (result == noErr,
                   @"Unable to set the patch on a soundfont file. Error code:%d '%s'",
                   (int) result,
                   fixOSResult(result));
        
	}

	return result;
}

-(OSStatus) loadSF2FromURL: (NSURL *)bankURL withPatch: (int)presetNumber sampler:(AudioUnit)sampler
{
    OSStatus result = noErr;
    
    AUSamplerBankPresetData bpdata;
    bpdata.bankURL  = (__bridge CFURLRef) bankURL;
    bpdata.bankMSB  = kAUSampler_DefaultMelodicBankMSB;
    bpdata.bankLSB  = kAUSampler_DefaultBankLSB;
    bpdata.presetID = (UInt8) presetNumber;
    
    result = AudioUnitSetProperty(sampler,
                                  kAUSamplerProperty_LoadPresetFromBank,
                                  kAudioUnitScope_Global,
                                  0,
                                  &bpdata,
                                  sizeof(bpdata));
    
    NSAssert (result == noErr,
               @"Unable to set the preset property on the Sampler. Error code:%d '%s'",
               (int) result,
               fixOSResult(result));
    
    return result;
}

- (OSStatus) configUnit:(AudioUnit)unit
{
    OSStatus result = noErr;
    UInt32 framesPerSlice = 0;
    UInt32 framesPerSlicePropertySize = sizeof (framesPerSlice);
    UInt32 sampleRatePropertySize = sizeof (_graphSampleRate);
    
    result =    AudioUnitSetProperty (
                                      unit,
                                      kAudioUnitProperty_SampleRate,
                                      kAudioUnitScope_Output,
                                      0,
                                      &_graphSampleRate,
                                      sampleRatePropertySize
                                      );
    
    NSAssert (result == noErr, @"AudioUnitSetProperty (set Sampler unit output stream sample rate). Error code: %d '%s'", (int) result, fixOSResult(result));
    
    result =    AudioUnitGetProperty (
                                      unit,
                                      kAudioUnitProperty_MaximumFramesPerSlice,
                                      kAudioUnitScope_Global,
                                      0,
                                      &framesPerSlice,
                                      &framesPerSlicePropertySize
                                      );
    
    NSAssert (result == noErr, @"Unable to retrieve the maximum frames per slice property from the I/O unit. Error code: %d '%s'", (int) result, fixOSResult(result));
    
    return result;
}

- (OSStatus) configureAndStartAudioProcessingGraph: (AUGraph) graph
{
    OSStatus result = noErr;
    
    result = AudioUnitInitialize (_ioUnit);
    NSAssert (result == noErr, @"Unable to initialize the I/O unit. Error code: %d '%s'", (int) result, fixOSResult(result));

    [self configUnit:_ioUnit];
    [self configUnit:_mixerUnit];
    
    result = AUGraphInitialize (graph);
    NSAssert (result == noErr, @"Unable to initialze AUGraph object. Error code: %d '%s'", (int) result, fixOSResult(result));
    
    result = AUGraphStart (graph);
    NSAssert (result == noErr, @"Unable to start audio processing graph. Error code: %d '%s'", (int) result, fixOSResult(result));
#if DEBUG
    CAShow (graph);
#endif

    return result;
}

@end
