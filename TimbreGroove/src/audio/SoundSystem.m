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

//#define DO_GRAPH_DUMP 1

static const unsigned int kNumSamplers = 8;
static const unsigned int kNumToneGenerators = 8;

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
    
    void *              _captureBuffer;
    PointerParamBlock   _bufferTrigger;
    RenderCBContext     _cbContext;

#ifdef LOAD_INSTRUMENT_PER_SCENE
    NSMutableArray * _instruments;
#else
    NSMutableArray * _samplers;
    NSMutableArray * _toneGenerators;
#endif
    
    int _numSamplers;
    
    UInt32 _ioFramesPerSlice;
    
    unsigned int _nextChannel;
    unsigned int _numBusses;
    AudioStreamBasicDescription _fasbd;
    AudioStreamBasicDescription _iasbd;
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
#ifdef LOAD_INSTRUMENT_PER_SCENE
        _instruments = [NSMutableArray new];
#endif
        [self setupAVSession];
        [self setupAUGraph];
        [self startGraph];
#ifdef DO_GRAPH_DUMP
        [self dumpGraph:_processGraph];
#endif
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
    FloatParamBlock(^NOOP_closure)(NSString const *) =
    ^FloatParamBlock(NSString const * name){
        return ^(float f) {
            [self handleParamChange:name value:f ];
        };
    };
    
    PointerParamBlock(^handleMidiMsg)(bool, bool) =
    ^PointerParamBlock(bool useDuration, bool onOff) {
        return ^(void * pmsg) {
            MIDINoteMessage * msg = pmsg;
#ifdef LOAD_INSTRUMENT_PER_SCENE
            id<MidiCapableProtocol> instrument = _instruments[msg->channel % kNumSamplers];
#else
            NSArray * instruments = msg->channel < kNumSamplers ? _samplers : _toneGenerators;
            id<MidiCapableProtocol> instrument = instruments[msg->channel % kNumSamplers];
#endif
            if( useDuration )
                [_midi sendNote:msg destination:instrument];
            else
                [_midi setNoteOnOff:msg destination:instrument on:onOff];
        };
    };
    
    [putHere addEntriesFromDictionary:
     @{
              kParamTempo: [Parameter withBlock:[NOOP_closure(kParamTempo) copy]],
              kParamPitch: [Parameter withBlock:[NOOP_closure(kParamPitch) copy]],
       kParamInstrumentP1: [Parameter withBlock:[NOOP_closure(kParamInstrumentP1) copy]],
       kParamInstrumentP2: [Parameter withBlock:[NOOP_closure(kParamInstrumentP2) copy]],
       kParamInstrumentP3: [Parameter withBlock:[NOOP_closure(kParamInstrumentP3) copy]],
       kParamInstrumentP4: [Parameter withBlock:[NOOP_closure(kParamInstrumentP4) copy]],
       kParamInstrumentP5: [Parameter withBlock:[NOOP_closure(kParamInstrumentP5) copy]],
       kParamInstrumentP6: [Parameter withBlock:[NOOP_closure(kParamInstrumentP6) copy]],
       kParamInstrumentP7: [Parameter withBlock:[NOOP_closure(kParamInstrumentP7) copy]],
       kParamInstrumentP8: [Parameter withBlock:[NOOP_closure(kParamInstrumentP8) copy]],
           kParamMIDINote: [Parameter withBlock:[handleMidiMsg(true,false) copy]],
         kParamMIDINoteON: [Parameter withBlock:[handleMidiMsg(false,true) copy]],
        kParamMIDINoteOFF: [Parameter withBlock:[handleMidiMsg(false,false) copy]],

     }];
    
    NOOP_closure = nil;
    handleMidiMsg = nil;
}

-(void)triggersChanged:(Scene *)scene
{
    // scene might be nil, still works out ok
    
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

#ifdef LOAD_INSTRUMENT_PER_SCENE
-(void)dettachInstruments:(NSArray *)instruments
           toneGenerators:(NSArray *)toneGenerators
{
    for( Sampler * sampler in instruments )
    {
        [self unplugInstrumentFromBus:sampler];
        [sampler didDetachFromGraph];
    }
    
    for( ToneGeneratorProxy * tgp in toneGenerators )
    {
        [tgp didDetachFromGraph];
    }
    
    [self setMixerBusCount:0];
    _numBusses = 0;
    _nextChannel = 0;
    [_instruments removeAllObjects];
    [self refreshGraph];
}

-(void)reattachInstruments:(NSArray *)instruments
            toneGenerators:(NSArray *)toneGenerators
{
    int bus = 0;
    for( Sampler * sampler in instruments )
    {
        [_instruments addObject:sampler];
        [self setMixerBusCount:bus+1];
        [sampler didAttachToGraph:sampler.channel];
        [self plugInstrumentIntoBus:sampler atChannel:sampler.channel];
        ++bus;
    }
    for( ToneGeneratorProxy * tgp in toneGenerators )
    {
        [_instruments addObject:tgp];
        [self setMixerBusCount:bus+1];
        [tgp didAttachToGraph:tgp.channel];
        ++bus;
    }
    _nextChannel = bus;
    _numBusses = bus;
    [self refreshGraph];
}
#endif

-(Sampler *)loadInstrumentFromConfig:(ConfigInstrument *)config
{
#ifdef LOAD_INSTRUMENT_PER_SCENE
    [self setMixerBusCount:++_numBusses];
    Sampler * sampler = [Sampler samplerWithAUGraph:_processGraph];
    [_instruments addObject:sampler];
    [sampler instantiateAU];
    [self configUnit:sampler.sampler];
    CheckError( AudioUnitInitialize(sampler.sampler), "Could not initialize sampler");
    [sampler loadSound:config midi:_midi];
    int channel = _nextChannel++;
    [sampler didAttachToGraph:channel];
    [self plugInstrumentIntoBus:sampler atChannel:channel];
    return sampler;
#else
    for( Sampler * sampler in _samplers )
    {
        if( sampler.available )
        {
            [sampler loadSound:config midi:_midi];
            return sampler;
        }
    }
    return nil;
#endif
}

-(ToneGeneratorProxy *)loadToneGeneratorFromConfig:(ConfigToneGenerator *)config
{
#ifdef LOAD_INSTRUMENT_PER_SCENE    
    [self setMixerBusCount:++_numBusses];
    int channel = _nextChannel++;
    ToneGeneratorProxy * tgProxy = [ToneGeneratorProxy toneGeneratorWithMixerAU:_mixerUnit];
    [_instruments addObject:tgProxy];
    unsigned long asbdSize = sizeof(_fasbd);
    CheckError(AudioUnitSetProperty(_mixerUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    channel,
                                    &_fasbd,
                                    asbdSize), "ugh tg fmt fail");
    
    tgProxy.generator = [tgProxy loadGenerator:config midi:_midi];
    [tgProxy didAttachToGraph:channel];
    
    return tgProxy;
    
#else
    for( ToneGeneratorProxy * tgProxy in _toneGenerators )
    {
        if( !tgProxy.generator )
        {
            tgProxy.generator = [tgProxy loadGenerator:config midi:_midi];
            return tgProxy;
        }
    }
    return nil;
#endif
}

-(void)unplugInstrumentFromBus:(Sampler *)instrument
{
    OSStatus result;

    result = AUGraphDisconnectNodeInput(_processGraph,
                                        _mixerNode,
                                        instrument.channel);
    
    CheckError(result,"Unable to disconnect the nodes in the audio processing graph.");
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

#ifndef LOAD_INSTRUMENT_PER_SCENE
    _samplers = [NSMutableArray new];
    for( int i = 0; i < kNumSamplers; i++ )
    {
        // this will call AUGraphAddNode so we do it here
        [_samplers addObject:[Sampler samplerWithAUGraph:_processGraph]];
    }
#endif
    
    CheckError(AUGraphOpen (_processGraph),                                    "Unable to open the audio processing graph.");
    CheckError(AUGraphNodeInfo (_processGraph, _mixerNode, 0, &_mixerUnit),    "Unable to obtain a reference to the mixer unit.");
    CheckError(AUGraphNodeInfo (_processGraph, eqNode,     0, &_masterEQUnit), "Unable to obtain a reference to the master EQ unit.");
    CheckError(AUGraphNodeInfo (_processGraph, cvNode,     0, &cvUnit),        "Unable to obtain a reference to the master EQ unit.");
    CheckError(AUGraphNodeInfo (_processGraph, ioNode,     0, &_ioUnit),       "Unable to obtain a reference to the I/O unit.");

#ifndef LOAD_INSTRUMENT_PER_SCENE
    // this requires _mixerUnit so we do it here
    _toneGenerators = [NSMutableArray new];
    for( int t = kNumSamplers; t < kNumSamplers+kNumToneGenerators; t++ )
    {
        [_toneGenerators addObject:[ToneGeneratorProxy toneGeneratorWithChannel:t andMixerAU:_mixerUnit]];
    }
    
    [self setMixerBusCount:kNumSamplers+kNumToneGenerators];

    // This will call AUGraphNodeInfo so we do it here
    [_samplers each:^(Sampler * sampler) { [sampler setNodeIntoGraph]; }];
    
    memset(&_fasbd, 0, sizeof(_fasbd));
    memset(&_iasbd, 0, sizeof(_iasbd));
#endif

    unsigned long asbdSize = sizeof(_fasbd);
    CheckError(AudioUnitGetProperty(_masterEQUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &_fasbd, &asbdSize), "ugh fmt 1");
    CheckError(AudioUnitGetProperty(_mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &_iasbd, &asbdSize), "ugh fmt 2");
    CheckError(AudioUnitSetProperty(cvUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input,  0, &_iasbd, asbdSize), "ugh fmt 3");
    CheckError(AudioUnitSetProperty(cvUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &_fasbd, asbdSize), "ugh fmt 4");
    _cbContext.asbd = _fasbd;

#ifndef LOAD_INSTRUMENT_PER_SCENE
    
    // This establishes the input format for the toneGenerators to be float
    // a.o.t. 8.24 Fixed (aka Signed Int 32)
    for( int m = kNumSamplers; m < kNumSamplers+kNumToneGenerators; m++ )
    {
        CheckError(AudioUnitSetProperty(_mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input,  m, &_fasbd, asbdSize), "ugh tg fmt fail");
    }
#endif
    
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
    
#ifndef LOAD_INSTRUMENT_PER_SCENE
    [_samplers enumerateObjectsUsingBlock:^(Sampler * sampler, NSUInteger s, BOOL *stop)
    {
        [self configUnit:sampler.sampler];
        CheckError( AudioUnitInitialize(sampler.sampler), "Could not initialize sampler");
        [self plugInstrumentIntoBus:sampler atChannel:s];
    }];
#endif
    
    result = AUGraphInitialize (_processGraph);
    CheckError(result,"Unable to initialze AUGraph object.");
    
    return result;
}

-(OSStatus)refreshGraph
{
    CheckError(AUGraphUpdate(_processGraph, NULL), "AUGraphUpdate failed" ); // NULL for synchronous

#ifdef DO_GRAPH_DUMP
    [self dumpGraph:_processGraph];
#endif
    return noErr;
}

@end
