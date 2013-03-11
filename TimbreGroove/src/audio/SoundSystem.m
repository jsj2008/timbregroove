//
//  Mixer.m
//  TimbreGroove
//
//  Created by victor on 1/27/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "SoundSystem.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "Config.h"
#import "SoundSystem+Diag.h"
#import "SoundSystemParameters.h"
#import "Midi.h"
#import "RingBuffer.h"
#import <libkern/OSAtomic.h>
#import "Names.h"
#import "Instrument.h"
#import "Scene.h"

void _CheckError( OSStatus error, const char *operation) {
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


static SoundSystem * __sharedSoundSystem;


//..............................................................................
//..............................................................................
//..............................................................................

// hard to tell where to set this number. The number of frames coming in
// can jump from 512 to 8x that without warning but since we can only
// ever interpret kFramesForDisplay (~512) at a time we only store that much
// TODO: Maybe want to think about downsampling
// but that could be awefully CPU expensive if inNumberFrames is some
// crazy number like 8k.
// Arrived at '16' because there seems to be an average of 5-10 dropped
// frames per UI thread fetch (vs. audio thread store) and the RingBuffer
// will step up to power of 2 anyway.
// This could probably set to something like '4' b/c the UI thread
// only ever picks up the latest slice but it just seem like by bumping
// this number huge, we likely avoid having the audio thread write
// directly into the same slot that we that is currently be read from
#define FRAME_MAX (kFramesForDisplay * 16)

typedef struct tagRenderCBContext {
    AudioStreamBasicDescription asbd;
    RingBufferOpaque  rbo;
    int32_t /*UInt32*/ fetchCount; // mark the last store (also: dropCount)
} RenderCBContext;

OSStatus renderCallback(
                    void *                         inRefCon,
                    AudioUnitRenderActionFlags *   ioActionFlags,
                    const AudioTimeStamp *         inTimeStamp,
                    UInt32                         inBusNumber,
                    UInt32                         inNumberFrames,
                    AudioBufferList *              ioData)
{
    if( (*ioActionFlags & kAudioUnitRenderAction_PostRender) == 0 ||
            inNumberFrames < kFramesForDisplay )
    {
        return noErr;
    }
    
    RenderCBContext * context = inRefCon;
    
    if( !context->rbo )
    {
        context->rbo = RingBuffer(context->asbd.mChannelsPerFrame,
                                  context->asbd.mBytesPerFrame,
                                  FRAME_MAX);
    }

    // Store to the next timeslot b/c display thread may be
    // reading from current 'fetchCount' slot
    SInt64 ts = (context->fetchCount + 1) * kFramesForDisplay;
    
    // only store what the display can handle
    RingBufferStore(context->rbo, ioData, kFramesForDisplay, ts );

    OSAtomicCompareAndSwap32Barrier(context->fetchCount,
                                    context->fetchCount+1,
                                    (volatile int32_t *)&context->fetchCount);
    
    return noErr;
}
//..............................................................................
//..............................................................................
//..............................................................................

@interface SoundSystem () {
    
    AUGraph          _processingGraph;
    AudioUnit        _ioUnit;
    AUNode           _mixerNode;
    AudioStreamBasicDescription _stdASBD;
    
    void *              _captureBuffer;
    PointerParamBlock   _bufferTrigger;
    RenderCBContext     _cbContext;

    int _busCount;
}

@end

@implementation SoundSystem


-(id)init
{
    self = [super init];
    if( self )
    {
        _cbContext.rbo = 0;
        
        [self setupAVSession];
        [self setupStdASBD]; // assumes _graphSampleRate
        [self setupAUGraph];
        [self startGraph];
    }
    return self;
}

-(void)dealloc
{
    [self releaseCaptureResources];

}

-(void)releaseCaptureResources
{
    if( _captureBuffer )
    {
        free(_captureBuffer);
        _captureBuffer = NULL;
    }
    if( _cbContext.rbo )
    {
        RingBufferRelease(_cbContext.rbo);
        _cbContext.rbo = NULL;
    }
    
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


+(SoundSystem *)sharedInstance
{
    @synchronized (self) {
        if( !__sharedSoundSystem )
            __sharedSoundSystem = [SoundSystem new];
    }
    return __sharedSoundSystem;
}

-(void)triggersChanged:(Scene *)scene
{
    PointerParamBlock newTrigger = [scene.triggers getPointerTrigger:kTriggerAudioFrame];
    
    if( _bufferTrigger )
    {
        if( !newTrigger )
        {
            CheckError(AudioUnitRemoveRenderNotify(_masterEQUnit, renderCallback, &_cbContext), "Could not unset callback");
            [self releaseCaptureResources];
        }
    }
    if( newTrigger )
    {
        if( !_bufferTrigger )
        {
            CheckError(AudioUnitAddRenderNotify(_masterEQUnit, renderCallback, &_cbContext), "Could not set callback");
        }
    }
    _bufferTrigger = newTrigger;
}

-(void)update:(NSTimeInterval)dt
{
    if( _bufferTrigger )
    {
        RenderCBContext ctx = _cbContext; // copy in case AU callback writes while we do this
        
        if( ctx.fetchCount )
        {
            if( !_captureBuffer )
            {
                UInt32 captureByteSize;
                captureByteSize = kFramesForDisplay * ctx.asbd.mBytesPerFrame * 2; // 2 channels
                _captureBuffer = malloc(sizeof(AudioBufferList)+sizeof(AudioBuffer)+captureByteSize);
                AudioBufferList * abl = _captureBuffer;
                Byte * dataBuff = ((Byte *)&abl->mBuffers[1].mData) + sizeof(void *);
                UInt32 channelBufferSize = captureByteSize / 2;
                abl->mNumberBuffers = 2;
                abl->mBuffers[0].mNumberChannels = 1;
                abl->mBuffers[0].mDataByteSize = channelBufferSize;
                abl->mBuffers[0].mData = dataBuff;
                abl->mBuffers[1].mNumberChannels = 1;
                abl->mBuffers[1].mDataByteSize = channelBufferSize;
                abl->mBuffers[1].mData = dataBuff + channelBufferSize;
            }
            
            // Ringbuffer will return silence (all zeroes) if our fetch
            // here is no longer available - iow, there was too much
            // lag betweeen store vs. fetch
            SInt64 ts = ctx.fetchCount * kFramesForDisplay;
            
            RingBufferFetch(ctx.rbo, _captureBuffer, kFramesForDisplay, ts);
            
            _bufferTrigger(_captureBuffer);
            
            OSAtomicCompareAndSwap32Barrier(_cbContext.fetchCount,
                                            0,
                                            (volatile int32_t *)&_cbContext.fetchCount);
        }
    }
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

-(Instrument *)loadInstrumentFromConfig:(ConfigInstrument *)config intoChannel:(int)channel
{
    return [Instrument instrumentWithConfig:config andGraph:_processingGraph atChannel:channel];
}

-(void)plugInstrumentIntoBus:(Instrument *)instrument
{
    OSStatus result;

    ++_busCount;
    [self setupMasterMixer];
    
    if( !instrument.configured )
    {
        [self configUnit:instrument.sampler];
        instrument.configured = true;
    }

    Boolean wasRunning = FALSE;
    CheckError( AUGraphIsRunning(_processingGraph, &wasRunning), "Couldn't check for running graph");
    
    if( wasRunning )
        CheckError( AUGraphStop(_processingGraph), "Couldn't stop graph");
    
    result = AUGraphConnectNodeInput (_processingGraph,
                                      instrument.graphNode,
                                      0,
                                      _mixerNode,
                                      instrument.channel);
    CheckError(result,"Unable to interconnect the nodes in the audio processing graph.");
    
    
    //Boolean isUpdated;
    result = AUGraphUpdate(_processingGraph, NULL); // NULL forces synchronous update &isUpdated);
    CheckError(result,"Unable to update graph.");

    if( wasRunning )
        CheckError( AUGraphStart(_processingGraph), "Couldn't restart graph");
    
    NSLog(@"plugged %@ (%d) into bus: %d", instrument.description, (unsigned int)instrument.sampler, instrument.channel);
}

-(void)unplugInstrumentFromBus:(Instrument *)instrument
{
    OSStatus result;
    
    Boolean wasRunning;
    CheckError( AUGraphIsRunning(_processingGraph, &wasRunning), "Couldn't check for running graph");
    
    if( wasRunning )
        CheckError( AUGraphStop(_processingGraph), "Couldn't stop graph");
    
    AUNode node = _mixerNode;
    UInt32 bus  = instrument.channel;
    result = AUGraphDisconnectNodeInput(_processingGraph, node, bus);
    CheckError(result, "Unable to disconnect node");
    
    result = AUGraphUpdate(_processingGraph, NULL); // NULL forces synchronous update &isUpdated);
    CheckError(result,"Unable to update graph.");
    
    NSLog(@"UNplugged %@ (%d) from bus: %d", instrument.description, (unsigned int)instrument.sampler,
          (unsigned int)bus);
    
    if( wasRunning )
        CheckError( AUGraphStart(_processingGraph), "Couldn't restart graph");
    
    --_busCount;
    [self setupMasterMixer];
}

-(void)decomissionInstrument:(Instrument *)instrument
{
    [self unplugInstrumentFromBus:instrument];
    AUGraphRemoveNode(_processingGraph, instrument.graphNode);
}

-(OSStatus)setupMasterEQ
{
    OSStatus result;
    
    UInt32 numBands = 3; // kNUM_EQ_BANDS;
    result = AudioUnitSetProperty(_masterEQUnit, kAUNBandEQProperty_NumberOfBands,
                                  kAudioUnitScope_Global, 0, &numBands, sizeof(numBands));
    CheckError(result, "Could not set number of EQ bands");
    
    CheckError(AudioUnitAddRenderNotify(_masterEQUnit, renderCallback, &_cbContext), "Could not set callback");
    
    [SoundSystemParameters configureEQ:_masterEQUnit];
    return result;
}

-(OSStatus)setupAUGraph
{
    OSStatus result = noErr;
    AUNode ioNode, eqNode, cvNode;
    AudioUnit cvUnit;

    CheckError(NewAUGraph (&_processingGraph),"Unable to create an AUGraph object.");
    
    AudioComponentDescription cd = {};
    cd.componentManufacturer     = kAudioUnitManufacturer_Apple;
    cd.componentFlags            = 0;
    cd.componentFlagsMask        = 0;
    cd.componentType             = kAudioUnitType_Mixer;
    cd.componentSubType          = kAudioUnitSubType_MultiChannelMixer;
    CheckError(AUGraphAddNode (_processingGraph, &cd, &_mixerNode),"Unable to add the Mixer unit to the audio processing graph.");

    cd.componentType    = kAudioUnitType_Effect;
    cd.componentSubType = kAudioUnitSubType_NBandEQ;
    CheckError(AUGraphAddNode (_processingGraph, &cd, &eqNode),"Unable to add the master EQ unit to the audio processing graph.");

    cd.componentType    = kAudioUnitType_FormatConverter;
    cd.componentSubType = kAudioUnitSubType_AUConverter;
    CheckError(AUGraphAddNode (_processingGraph, &cd, &cvNode),"Unable to add the master EQ unit to the audio processing graph.");

    cd.componentType    = kAudioUnitType_Output;
    cd.componentSubType = kAudioUnitSubType_RemoteIO;
    CheckError(AUGraphAddNode (_processingGraph, &cd, &ioNode),"Unable to add the Output unit to the audio processing graph.");

    CheckError(AUGraphOpen (_processingGraph),                                    "Unable to open the audio processing graph.");
    CheckError(AUGraphNodeInfo (_processingGraph, _mixerNode, 0, &_mixerUnit),    "Unable to obtain a reference to the mixer unit.");
    CheckError(AUGraphNodeInfo (_processingGraph, eqNode,     0, &_masterEQUnit), "Unable to obtain a reference to the master EQ unit.");
    CheckError(AUGraphNodeInfo (_processingGraph, cvNode,     0, &cvUnit),        "Unable to obtain a reference to the master EQ unit.");
    CheckError(AUGraphNodeInfo (_processingGraph, ioNode,     0, &_ioUnit),       "Unable to obtain a reference to the I/O unit.");

    AudioStreamBasicDescription fasbd = {0};
    AudioStreamBasicDescription iasbd = {0};
    unsigned long asbdSize = sizeof(fasbd);
    CheckError(AudioUnitGetProperty(_masterEQUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &fasbd, &asbdSize), "ugh fmt 1");
    CheckError(AudioUnitGetProperty(_mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &iasbd, &asbdSize), "ugh fmt 2");
    CheckError(AudioUnitSetProperty(cvUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input,  0, &iasbd, asbdSize), "ugh fmt 3");
    CheckError(AudioUnitSetProperty(cvUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &fasbd, asbdSize), "ugh fmt 4");
    _cbContext.asbd = fasbd;
    
    [self setupMasterEQ];
    
    result = AUGraphConnectNodeInput (_processingGraph, _mixerNode, 0, cvNode, 0);
    CheckError(result,"Unable to interconnect the mixer/conv nodes in the audio processing graph.");

    result = AUGraphConnectNodeInput (_processingGraph, cvNode, 0, eqNode, 0);
    CheckError(result,"Unable to interconnect the conv/eq nodes in the audio processing graph.");
    
    result = AUGraphConnectNodeInput (_processingGraph, eqNode, 0, ioNode, 0);
    CheckError(result,"Unable to interconnect the eq/rio nodes in the audio processing graph.");

    return result;
}

-(void)setupMasterMixer
{
    OSStatus result;
    result = AudioUnitSetProperty (_mixerUnit,
                                   kAudioUnitProperty_ElementCount,
                                   kAudioUnitScope_Input,
                                   0,
                                   &_busCount,
                                   sizeof (_busCount)
                                   );
    CheckError(result,"Unable to set buscount on mixer.");
    
}

- (OSStatus) configUnit:(AudioUnit)unit
{
    OSStatus result = noErr;
    UInt32 sampleRatePropertySize = sizeof (_graphSampleRate);
    
    result =    AudioUnitSetProperty (
                                      unit,
                                      kAudioUnitProperty_SampleRate,
                                      kAudioUnitScope_Output,
                                      0,
                                      &_graphSampleRate,
                                      sampleRatePropertySize
                                      );
    
    CheckError(result,"AudioUnitSetProperty (set unit output stream sample rate).");
    
    UInt32 framesPerSlice = 4096;
    result =    AudioUnitSetProperty (
                                      unit,
                                      kAudioUnitProperty_MaximumFramesPerSlice,
                                      kAudioUnitScope_Global,
                                      0,
                                      &framesPerSlice,
                                      sizeof (framesPerSlice)
                                      );
    
    CheckError(result,"Unable to set the maximum frames per slice property from the I/O unit.");
    
    return result;
}

- (OSStatus) startGraph
{
    OSStatus result = noErr;
    
    result = AudioUnitInitialize(_ioUnit); // sampling rate is otherwise not writable
    CheckError(result, "Could not initialize ioUnit");
    
    [self configUnit:_mixerUnit];
    [self configUnit:_masterEQUnit];
    [self configUnit:_ioUnit];
    
    result = AUGraphInitialize (_processingGraph);
    CheckError(result,"Unable to initialze AUGraph object.");
    
    result = AUGraphStart (_processingGraph);
    CheckError(result,"Unable to start audio processing graph.");

    return result;
}

@end
