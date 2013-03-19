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
#import "Sampler.h"
#import "Scene.h"
#import "ToneGenerator.h"

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
    if( (*ioActionFlags & kAudioUnitRenderAction_PostRender) == 0 )
    {
        return noErr;
    }

    if( inNumberFrames < kFramesForDisplay )
    {
        TGLog(LLShitsOnFire, @"Expecting: %d frame - got: %d",kFramesForDisplay,inNumberFrames);
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
    
    AudioUnit        _ioUnit;
    AUNode           _mixerNode;
    AudioStreamBasicDescription _stdASBD;
    
    void *              _captureBuffer;
    PointerParamBlock   _bufferTrigger;
    RenderCBContext     _cbContext;

    NSMutableArray * _samplers;
    NSMutableArray * _toneGenerators;
    
    int _numSamplers;
    
    UInt32 _ioFramesPerSlice;
}

@end

#define EMPTY_CHANNEL (AudioUnit)-1

@implementation SoundSystem

-(id)init
{
    self = [super init];
    if( self )
    {
        _midi = [[Midi alloc] init];
        _cbContext.rbo = 0;
        
        [self setupAVSession];
        [self setupStdASBD]; // assumes _graphSampleRate
        [self setupAUGraph];
        [self startGraph];
        [self dumpGraph:_processGraph];
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
    _cbContext.fetchCount = 0;
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

-(void)handleParamChange:(NSString const *)paramName value:(float)value
{
    
}

-(void)getParameters:(NSMutableDictionary *)putHere
{
    FloatParamBlock(^closure)(NSString const * name) =
    ^FloatParamBlock(NSString const * name){
        return ^(float f) {
            [self handleParamChange:name value:f ];
        };
    };
    
    [putHere addEntriesFromDictionary:
     @{
              kParamTempo: [Parameter withBlock:[closure(kParamTempo) copy]],
              kParamPitch: [Parameter withBlock:[closure(kParamPitch) copy]],
       kParamInstrumentP1: [Parameter withBlock:[closure(kParamInstrumentP1) copy]],
       kParamInstrumentP2: [Parameter withBlock:[closure(kParamInstrumentP2) copy]],
       kParamInstrumentP3: [Parameter withBlock:[closure(kParamInstrumentP3) copy]],
       kParamInstrumentP4: [Parameter withBlock:[closure(kParamInstrumentP4) copy]],
       kParamInstrumentP5: [Parameter withBlock:[closure(kParamInstrumentP5) copy]],
       kParamInstrumentP6: [Parameter withBlock:[closure(kParamInstrumentP6) copy]],
       kParamInstrumentP7: [Parameter withBlock:[closure(kParamInstrumentP7) copy]],
       kParamInstrumentP8: [Parameter withBlock:[closure(kParamInstrumentP8) copy]],
           kParamMIDINote: [Parameter withBlock:[^(MIDINoteMessage *msg) {
        if( msg->channel < _numSamplers )
        {
            Sampler * sampler = _samplers[msg->channel];
            [sampler sendNote:msg];
        }
        else
        {
            ToneGeneratorProxy * tgp = _toneGenerators[msg->channel - _numSamplers];
            [tgp.generator sendNote:msg];
        }
    } copy]]
     }];
}

-(void)triggersChanged:(Scene *)scene
{
    // scene might be nil, still works out ok
    
    PointerParamBlock newTrigger = [scene.triggers getPointerTrigger:kTriggerAudioFrame];
    
    if( _bufferTrigger )
    {
        if( !newTrigger )
        {
#ifdef AUDIO_BUFFER_NATIVE_FLOATS
            CheckError(AudioUnitRemoveRenderNotify(_masterEQUnit, renderCallback, &_cbContext), "Could not unset callback");
#else
            CheckError(AUGraphRemoveRenderNotify( _processGraph, renderCallback, &_cbContext), "Could not remove graph render notify");
#endif
            [self releaseCaptureResources];
        }
    }
    if( newTrigger )
    {
        if( !_bufferTrigger )
        {
#ifdef AUDIO_BUFFER_NATIVE_FLOATS
            CheckError(AudioUnitAddRenderNotify(_masterEQUnit, renderCallback, &_cbContext), "Could not set callback");
#else
            CheckError(AUGraphAddRenderNotify( _processGraph, renderCallback, &_cbContext), "Could not add graph render notify");
#endif
        }
    }
    _bufferTrigger = newTrigger;
    
    TGLog(LLCaptureOps, @"Buffer trigger: %p for %@",(__bridge void *)_bufferTrigger,scene);
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
            
#ifdef DEBUG
            static int capCount = 0;
            if( capCount++ % 120 == 0 )
                TGLog(LLCaptureOps, @"Sending cap buffer: %p",_captureBuffer);
#endif
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
    if (audioSessionError != nil) {TGLog(LLShitsOnFire, @"Error setting audio session category."); return NO;}
    
    _graphSampleRate = 44100.0;
    
    [mySession setPreferredSampleRate: _graphSampleRate error: &audioSessionError];
    if (audioSessionError != nil) {TGLog(LLShitsOnFire, @"Error setting preferred hardware sample rate."); return NO;}
    
    [mySession setActive: YES error: &audioSessionError];
    if (audioSessionError != nil) {TGLog(LLShitsOnFire, @"Error activating the audio session."); return NO;}
    
    _graphSampleRate = mySession.sampleRate;
    
    return YES;
}

-(Sampler *)loadInstrumentFromConfig:(ConfigInstrument *)config
{
    for( Sampler * sampler in _samplers )
    {
        if( sampler.available )
        {
            [sampler loadSound:config];
            return sampler;
        }
    }
    return nil;
}

-(ToneGeneratorProxy *)loadToneGeneratorFromConfig:(ConfigToneGenerator *)config
{
    for( ToneGeneratorProxy * tgProxy in _toneGenerators )
    {
        if( !tgProxy.generator )
        {
            tgProxy.generator = [tgProxy loadGenerator:config];
            return tgProxy;
        }
    }
    return nil;
}

-(void)plugInstrumentIntoBus:(Sampler *)instrument atChannel:(int)channel
{
    OSStatus result;

    instrument.channel = channel;
    
    result = AUGraphConnectNodeInput (_processGraph,
                                      instrument.graphNode,
                                      0,
                                      _mixerNode,
                                      instrument.channel);
    CheckError(result,"Unable to interconnect the nodes in the audio processing graph.");
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

    CheckError(NewAUGraph (&_processGraph),"Unable to create an AUGraph object.");
    
    AudioComponentDescription cd = {};
    cd.componentManufacturer     = kAudioUnitManufacturer_Apple;
    cd.componentFlags            = 0;
    cd.componentFlagsMask        = 0;
    cd.componentType             = kAudioUnitType_Mixer;
    cd.componentSubType          = kAudioUnitSubType_MultiChannelMixer;
    CheckError(AUGraphAddNode (_processGraph, &cd, &_mixerNode),"Unable to add the Mixer unit to the audio processing graph.");

    cd.componentType    = kAudioUnitType_Effect;
    cd.componentSubType = kAudioUnitSubType_NBandEQ;
    CheckError(AUGraphAddNode (_processGraph, &cd, &eqNode),"Unable to add the master EQ unit to the audio processing graph.");

    cd.componentType    = kAudioUnitType_FormatConverter;
    cd.componentSubType = kAudioUnitSubType_AUConverter;
    CheckError(AUGraphAddNode (_processGraph, &cd, &cvNode),"Unable to add the master EQ unit to the audio processing graph.");

    cd.componentType    = kAudioUnitType_Output;
    cd.componentSubType = kAudioUnitSubType_RemoteIO;
    CheckError(AUGraphAddNode (_processGraph, &cd, &ioNode),"Unable to add the Output unit to the audio processing graph.");

    _samplers = [NSMutableArray new];
    for( int i = 0; i < 8; i++ )
    {
        [_samplers addObject:[[Sampler alloc] initWithGraph:_processGraph]];
    }
    
    CheckError(AUGraphOpen (_processGraph),                                    "Unable to open the audio processing graph.");
    CheckError(AUGraphNodeInfo (_processGraph, _mixerNode, 0, &_mixerUnit),    "Unable to obtain a reference to the mixer unit.");
    CheckError(AUGraphNodeInfo (_processGraph, eqNode,     0, &_masterEQUnit), "Unable to obtain a reference to the master EQ unit.");
    CheckError(AUGraphNodeInfo (_processGraph, cvNode,     0, &cvUnit),        "Unable to obtain a reference to the master EQ unit.");
    CheckError(AUGraphNodeInfo (_processGraph, ioNode,     0, &_ioUnit),       "Unable to obtain a reference to the I/O unit.");

    _toneGenerators = [NSMutableArray new];
    for( int t = 8; t < 16; t++ )
    {
        [_toneGenerators addObject:[[ToneGeneratorProxy alloc] initWithChannel:t andAU:_mixerUnit]];
    }
    
    _numSamplers = [_samplers count];
    [self setMixerBusCount:_numSamplers+[_toneGenerators count]];
    
    [_samplers each:^(Sampler * sampler) { [sampler setNodeIntoGraph]; }];
    
    AudioStreamBasicDescription fasbd = {0};
    AudioStreamBasicDescription iasbd = {0};
    unsigned long asbdSize = sizeof(fasbd);
    CheckError(AudioUnitGetProperty(_masterEQUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &fasbd, &asbdSize), "ugh fmt 1");
    CheckError(AudioUnitGetProperty(_mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &iasbd, &asbdSize), "ugh fmt 2");
    CheckError(AudioUnitSetProperty(cvUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input,  0, &iasbd, asbdSize), "ugh fmt 3");
    CheckError(AudioUnitSetProperty(cvUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &fasbd, asbdSize), "ugh fmt 4");
    _cbContext.asbd = fasbd;

    for( int m = 8; m < 16; m++ )
    {
        CheckError(AudioUnitSetProperty(_mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input,  m, &fasbd, asbdSize), "ugh tg fmt fail");
    }
    
    [self setupMasterEQ];
    
    result = AUGraphConnectNodeInput (_processGraph, _mixerNode, 0, cvNode, 0);
    CheckError(result,"Unable to interconnect the mixer/conv nodes in the audio processing graph.");

    result = AUGraphConnectNodeInput (_processGraph, cvNode, 0, eqNode, 0);
    CheckError(result,"Unable to interconnect the conv/eq nodes in the audio processing graph.");
    
    result = AUGraphConnectNodeInput (_processGraph, eqNode, 0, ioNode, 0);
    CheckError(result,"Unable to interconnect the eq/rio nodes in the audio processing graph.");

    return result;
}

-(void)setMixerBusCount:(int)busCount
{
    OSStatus result;
    result = AudioUnitSetProperty (_mixerUnit,
                                   kAudioUnitProperty_ElementCount,
                                   kAudioUnitScope_Input,
                                   0,
                                   &busCount,
                                   sizeof (busCount)
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
    
    UInt32 framesPerSlice = _ioFramesPerSlice; // 4096;
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
    
    UInt32 fpsSize = sizeof(_ioFramesPerSlice);
    result = AudioUnitGetProperty(_ioUnit,
                                  kAudioUnitProperty_MaximumFramesPerSlice,
                                  kAudioUnitScope_Global,
                                  0, &_ioFramesPerSlice, &fpsSize);
    CheckError(result, "Could not get frames per slice");    
    
    [self configUnit:_mixerUnit];
    [self configUnit:_masterEQUnit];
    [self configUnit:_ioUnit];
    
    [_samplers each:^(Sampler * sampler) {
        [self configUnit:sampler.sampler];
        OSStatus result = AudioUnitInitialize(sampler.sampler);
        CheckError(result, "Could not initialize sampler");
    }];
    
    [_samplers enumerateObjectsUsingBlock:^(Sampler * sampler, NSUInteger idx, BOOL *stop) {
        [sampler setupMidi:_midi];
        [self plugInstrumentIntoBus:sampler atChannel:idx];
	}];
    
    result = AUGraphInitialize (_processGraph);
    CheckError(result,"Unable to initialze AUGraph object.");
    
    return result;
}

@end
