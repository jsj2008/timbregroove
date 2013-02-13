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
#import "Mixer+Midi.h"
#import "RingBuffer.h"

#ifndef DEBUG
#undef NSAssert
#define NSAssert(cond,str,...)
#endif

void CheckError( OSStatus error, const char *operation) {
    if (error == noErr)
        return;
    char errorString[ 20];        // See if it appears to be a 4-char-code
    *( UInt32 *)( errorString + 1) = CFSwapInt32HostToBig( error);
    if (isprint( errorString[ 1]) && isprint( errorString[ 2]) &&
        isprint( errorString[ 3]) && isprint( errorString[ 4]))
    {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    }
    else                        // No, format it as an integer
        sprintf( errorString, "%d %04X", (int) error, (int)error);
    fprintf( stderr, "Error: %s (%s)\n", operation, errorString);
    exit( 1);
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
    MIDITimeStamp _prevTimeStamp;
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
        _prevTimeStamp = 0;
    }
    
    return self;
}

-(AudioUnit)sampler
{
    return _samplerUnit;
}

-(void)addNoteCache:(int)note ts:(MIDITimeStamp)ts
{
    
}
-(void)playMidiFile:(NSString *)filename
{
    [[Mixer sharedInstance] playMidiFile:filename throughSampler:_samplerUnit];
}

-(OSStatus)playNote:(int)note forDuration:(NSTimeInterval)duration
{
    UInt32 noteNum = note;
    UInt32 onVelocity = 127;
    UInt32 noteCommand =     kMIDIMessage_NoteOn << 4 | 0;
    
    OSStatus result = noErr;
    result = MusicDeviceMIDIEvent (_samplerUnit,
                                   noteCommand,
                                   noteNum, onVelocity, 0);
    
    CheckError(result,"Unable to start note.");
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
    
    CheckError(result,"Unable to stop note.");
    return result;
}

@end
//..............................................................................
//..............................................................................
//..............................................................................

#define BUFFERS_IN_RING 10

typedef struct tagRenderCBContext {
    RingBufferOpaque rbo;
    long fetchCount;
    UInt32  numFrames;
    UInt32 bufferSize;
} RenderCBContext;

OSStatus renderCallback(
                    void *                            inRefCon,
                    AudioUnitRenderActionFlags *    ioActionFlags,
                    const AudioTimeStamp *            inTimeStamp,
                    UInt32                            inBusNumber,
                    UInt32                            inNumberFrames,
                    AudioBufferList *                ioData)
{
    if( (*ioActionFlags & kAudioUnitRenderAction_PostRender) == 0 )
        return noErr;
    
    RenderCBContext * context = inRefCon;
    
    UInt32 sz = 0;
    for( int i = 0; i < ioData->mNumberBuffers; i++ )
        sz += ioData->mBuffers[i].mDataByteSize;
    
    if( context->rbo )
    {
        if( sz != context->bufferSize )
        {
            RingBufferRelease(context->rbo);
            context->rbo = 0;
        }
    }

    if( !context->rbo )
    {
        context->rbo = RingBuffer(2, sizeof(AudioSampleType), sz * BUFFERS_IN_RING);
        context->bufferSize = sz;
    }

    double ts = CACurrentMediaTime();
    RingBufferStore(context->rbo, ioData, inNumberFrames, ts);
    
    ++context->fetchCount;
    
    context->numFrames = inNumberFrames;
    
    return noErr;
}
//..............................................................................
//..............................................................................
//..............................................................................

@interface Mixer () {
    NSDictionary *   _aliases;
    Float64          _graphSampleRate;
    unsigned int     _numSamplerUnits;
    unsigned int     _capSamplerUnits;
    RenderCBContext  _cbContext;
    
    AudioStreamBasicDescription _stdASBD;
    
    void * _captureBuffer;
    UInt32 _captureByteSize;
}
@end

@implementation Mixer

-(id)init
{
    self = [super init];
    if( self )
    {
        _capSamplerUnits = 8;
        _numSamplerUnits = 0;
        _samplerUnits = malloc(sizeof(AudioUnit)*_capSamplerUnits);
        memset(_samplerUnits, 0, sizeof(AudioUnit)*_capSamplerUnits);
        
        _cbContext.rbo = 0;
        
        _aliases = [[Config sharedInstance] valueForKey:@"sounds"];
        [self setupAVSession];
        [self setupStdASBD]; // assumes _graphSampleRate
        [self setupAUGraph];
        [self startGraph];
        [self setupMidi];
    }
    return self;
}

-(void)dealloc
{
    [self midiDealloc];
    free(_samplerUnits);
    if( _captureBuffer )
        free(_captureBuffer);
}

-(void)setupStdASBD
{
    size_t bytesPerSample = sizeof (AudioUnitSampleType);
    
    _stdASBD.mFormatID          = kAudioFormatLinearPCM;
    _stdASBD.mFormatFlags       = kAudioFormatFlagsAudioUnitCanonical; // signed int
    _stdASBD.mBytesPerPacket    = bytesPerSample;
    _stdASBD.mFramesPerPacket   = 1;
    _stdASBD.mBytesPerFrame     = bytesPerSample;
    _stdASBD.mChannelsPerFrame  = 2;                    // 2 indicates stereo
    _stdASBD.mBitsPerChannel    = 8 * bytesPerSample;
    _stdASBD.mSampleRate        = _graphSampleRate;
    
}

-(void)stowSamplerUnit:(AudioUnit)su
{
    if( _numSamplerUnits == _capSamplerUnits )
    {
        _capSamplerUnits += 8;
        AudioUnit * temp = malloc(sizeof(AudioUnit)*_capSamplerUnits);
        memset(temp, 0, sizeof(AudioUnit)*_capSamplerUnits);
        memcpy(temp, _samplerUnits, sizeof(AudioUnit)*_numSamplerUnits);
        free(_samplerUnits);
        _samplerUnits = temp;
    }
    _samplerUnits[_numSamplerUnits++] = su;
}

+(Mixer *)sharedInstance
{
    @synchronized (self) {
        if( !__sharedMixer )
            __sharedMixer = [Mixer new];
    }
    return __sharedMixer;
}

-(void)update:(MixerUpdate *)mixerUpdate
{
    mixerUpdate->audioBufferList = NULL;
    mixerUpdate->droppedCaptureFrames = 0;
    
    if( !_cbContext.fetchCount )
        return;
    
    if( !_captureBuffer || (_captureByteSize != _cbContext.bufferSize) )
    {
        if( _captureBuffer )
            free(_captureBuffer);
        _captureBuffer = malloc(sizeof(AudioBufferList)+sizeof(AudioBuffer)+_cbContext.bufferSize);
        AudioBufferList * abl = _captureBuffer;
        Byte * dataBuff = ((Byte *)&abl->mBuffers[1].mData) + sizeof(void *);
        UInt32 buffsz = _cbContext.bufferSize / 2;
        abl->mNumberBuffers = 2;
        abl->mBuffers[0].mNumberChannels = 1;
        abl->mBuffers[0].mDataByteSize = buffsz;
        abl->mBuffers[0].mData = dataBuff;
        abl->mBuffers[1].mNumberChannels = 1;
        abl->mBuffers[1].mDataByteSize = buffsz;
        abl->mBuffers[1].mData = dataBuff + buffsz;
        _captureByteSize = _cbContext.bufferSize;
    }

    int numFrames = _cbContext.numFrames;
    double ts = CACurrentMediaTime();
    RingBufferFetch(_cbContext.rbo, _captureBuffer, numFrames, ts);
    
    mixerUpdate->droppedCaptureFrames = _cbContext.fetchCount;
    mixerUpdate->audioBufferList = _captureBuffer;
    mixerUpdate->numFrames = numFrames;
    _cbContext.fetchCount = 0;
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
    
    CheckError(result,"Unable to set output gain.");
    
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
    [self stowSamplerUnit:sound.sampler];
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
    CheckError(result,"Unable to add the Sampler unit to the audio processing graph.");

    AudioUnit samplerUnit;
    result = AUGraphNodeInfo (_processingGraph, samplerNode, 0, &samplerUnit);
    CheckError(result,"Unable to obtain a reference to the Sampler unit.");
   
    UInt32 busCount = _numSamplerUnits + 1;
    result = AudioUnitSetProperty (_mixerUnit,
                                   kAudioUnitProperty_ElementCount,
                                   kAudioUnitScope_Input,
                                   0,
                                   &busCount,
                                   sizeof (busCount)
                                   );
    CheckError(result,"Unable to set buscount on mixer.");
    
    result = AUGraphConnectNodeInput (_processingGraph, samplerNode, 0, _mixerNode, busCount-1);
    CheckError(result,"Unable to interconnect the nodes in the audio processing graph.");
    
    [self configUnit:samplerUnit];
    
    Boolean isUpdated;
    result = AUGraphUpdate(_processingGraph, &isUpdated);
    CheckError(result,"Unable to update graph.");
    
    [self dumpParameters:samplerUnit forUnit:@"Sampler Unit"];
    [self dumpParameters:_mixerUnit forUnit:@"Mixer Unit"];
    [self dumpGraph];
    
    return samplerUnit;
}

-(OSStatus)setupAUGraph
{
    OSStatus result = noErr;
    AUNode ioNode;

    CheckError(NewAUGraph (&_processingGraph),"Unable to create an AUGraph object.");
    
    AudioComponentDescription cd = {};
    cd.componentManufacturer     = kAudioUnitManufacturer_Apple;
    cd.componentFlags            = 0;
    cd.componentFlagsMask        = 0;
    cd.componentType             = kAudioUnitType_Mixer;
    cd.componentSubType          = kAudioUnitSubType_MultiChannelMixer;
    CheckError(AUGraphAddNode (_processingGraph, &cd, &_mixerNode),"Unable to add the Mixer unit to the audio processing graph.");

    cd.componentType    = kAudioUnitType_Output;
    cd.componentSubType = kAudioUnitSubType_RemoteIO;
    CheckError(AUGraphAddNode (_processingGraph, &cd, &ioNode),"Unable to add the Output unit to the audio processing graph.");

    CheckError(AUGraphOpen (_processingGraph),                                 "Unable to open the audio processing graph.");
    CheckError(AUGraphNodeInfo (_processingGraph, _mixerNode, 0, &_mixerUnit), "Unable to obtain a reference to the I/O unit.");
    CheckError(AUGraphNodeInfo (_processingGraph, ioNode, 0, &_ioUnit),        "Unable to obtain a reference to the I/O unit.");

    CheckError(AudioUnitAddRenderNotify(_mixerUnit, renderCallback, &_cbContext), "Could not set callback");

    
    result = AUGraphConnectNodeInput (_processingGraph, _mixerNode, 0, ioNode, 0);
    CheckError(result,"Unable to interconnect the nodes in the audio processing graph.");
    
    result = AudioUnitSetProperty(_mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &_stdASBD, sizeof(_stdASBD));
    CheckError(result,"Unable to set RIO output stream format");
    
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
        CheckError(result, "Unable to set the patch on a soundfont file");
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
    CheckError(result, "Unable to set the preset property on the Sampler.");    
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
    
    CheckError(result,"AudioUnitSetProperty (set Sampler unit output stream sample rate).");
    
    result =    AudioUnitGetProperty (
                                      unit,
                                      kAudioUnitProperty_MaximumFramesPerSlice,
                                      kAudioUnitScope_Global,
                                      0,
                                      &framesPerSlice,
                                      &framesPerSlicePropertySize
                                      );
    
    CheckError(result,"Unable to retrieve the maximum frames per slice property from the I/O unit.");
    
    return result;
}

- (OSStatus) startGraph
{
    OSStatus result = noErr;
    
    result = AudioUnitInitialize (_ioUnit);
    CheckError(result,"Unable to initialize the I/O unit.");

    [self configUnit:_ioUnit];
    [self configUnit:_mixerUnit];
    
    result = AUGraphInitialize (_processingGraph);
    CheckError(result,"Unable to initialze AUGraph object.");
    
    result = AUGraphStart (_processingGraph);
    CheckError(result,"Unable to start audio processing graph.");

    [self dumpGraph];
    
    return result;
}

@end
