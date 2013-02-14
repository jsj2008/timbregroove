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
#import <libkern/OSAtomic.h>

const float kBottomOfOctiveRange = 0.05;
const float kTopOfOctiveRange = 5.0;
const AudioUnitParameterValue kEQBypassON  = 1;
const AudioUnitParameterValue kEQBypassOFF = 0;

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
    if( _cbContext.rbo )
        RingBufferRelease(_cbContext.rbo);
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

    RenderCBContext ctx = _cbContext; // copy in case AU callback writes while we do this
    
    if( ctx.fetchCount )
    {
        if( !_captureBuffer )
        {
            _captureByteSize = kFramesForDisplay * ctx.asbd.mBytesPerFrame * 2; // 2 channels
            _captureBuffer = malloc(sizeof(AudioBufferList)+sizeof(AudioBuffer)+_captureByteSize);
            AudioBufferList * abl = _captureBuffer;
            Byte * dataBuff = ((Byte *)&abl->mBuffers[1].mData) + sizeof(void *);
            UInt32 channelBufferSize = _captureByteSize / 2;
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

        mixerUpdate->audioBufferList = _captureBuffer;
        
        OSAtomicCompareAndSwap32Barrier(_cbContext.fetchCount,
                                        0,
                                        (volatile int32_t *)&_cbContext.fetchCount);
    }
    
    
    [self isPlayerDone];
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
    
    //Boolean isUpdated;
    result = AUGraphUpdate(_processingGraph, NULL); // NULL forces synchronous update &isUpdated);
    CheckError(result,"Unable to update graph.");
    
    [self dumpGraph];
    
    return samplerUnit;
}

-(OSStatus)setupMasterEQ
{
    OSStatus result;
    
    UInt32 numBands = kNUM_EQ_BANDS;
    result = AudioUnitSetProperty(_masterEQUnit, kAUNBandEQProperty_NumberOfBands, kAudioUnitScope_Global, 0, &numBands, sizeof(numBands));
    CheckError(result, "Could not set number of EQ bands");

    CheckError(AudioUnitAddRenderNotify(_masterEQUnit, renderCallback, &_cbContext), "Could not set callback");
    
    for( int i = 0; i < kNUM_EQ_BANDS; i++ )
    {
        result = AudioUnitSetParameter (_masterEQUnit,
                                        kAUNBandEQParam_FilterType + i,
                                        kAudioUnitScope_Global,
                                        0,
                                        kAUNBandEQFilterType_Parametric,
                                        0);
        CheckError(result,"Unable to set eq filter type.");
        
        result = AudioUnitSetParameter (_masterEQUnit,
                                        kAUNBandEQParam_BypassBand + i,
                                        kAudioUnitScope_Global,
                                        0,
                                        kEQBypassOFF,
                                        0);
        
        CheckError(result,"Unable to set eq bypass to OFF.");
        _selectedEQdBand = i;
        self.eqCenter = 0.5;
    }
    
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

    _mixerOutputGain = newGain;
}

-(void) setEqBandwidth:(AudioUnitParameterValue)eqBandwidth
{
    // 0.05 through 5.0 octaves
    AudioUnitParameterValue nativeValue = (eqBandwidth * (kTopOfOctiveRange-kBottomOfOctiveRange)) +
                                            (eqBandwidth * kBottomOfOctiveRange);
    //NSLog(@"eq bw set to %f <- %f", nativeValue, eqBandwidth);
    OSStatus result = AudioUnitSetParameter (
                                             _masterEQUnit,
                                             kAUNBandEQParam_Bandwidth + _selectedEQdBand,
                                             kAudioUnitScope_Global,
                                             0,
                                             nativeValue,
                                             0
                                             );
    
    CheckError(result,"Unable to set eq HiBandwidth.");

    _eqBandwidth = eqBandwidth;    
}

-(void) calcEQBandLow:(float *)lo andHigh:(float *)hi
{
    const float kLowestFreq = 20.0;
    float highestFreq = _graphSampleRate / 2.0;
    float singleEQBandRange = (highestFreq - kLowestFreq) / kNUM_EQ_BANDS;
    *lo = (singleEQBandRange * _selectedEQdBand) + kLowestFreq;
    *hi = *lo + singleEQBandRange;
}

-(void) setEqCenter:(AudioUnitParameterValue)eqCenter
{
    // 20 Hz to < Nyquist freq (sampleRate/2)
    float min, max;
    [self calcEQBandLow:&min andHigh:&max];
    AudioUnitParameterValue nativeValue = (eqCenter * (max-min)) + (min * eqCenter);
    //NSLog(@"eq center to %f <- %f", nativeValue, eqCenter);
    OSStatus result = AudioUnitSetParameter (
                                             _masterEQUnit,
                                             kAUNBandEQParam_Frequency + _selectedEQdBand,
                                             kAudioUnitScope_Global,
                                             0,
                                             nativeValue,
                                             0
                                             );
    
    CheckError(result,"Unable to set eq HiCenter.");
    
    _eqCenter = eqCenter;
}

-(void) setEqPeak:(AudioUnitParameterValue)eqPeak
{
    // –96 through +24 dB
    float min = -96;
    float max = 24;
    // TODO: I think this should be log() something other than "linear"
    AudioUnitParameterValue nativeValue = (eqPeak * (max-min)) + (min * eqPeak);
    //NSLog(@"eq[%d] peak to %f <- %f", _selectedEQdBand, nativeValue, eqPeak);
    
    //
    // 6db = (x * (24 + 96)) - 96;
    // 6 + 96 = x * 130;
    // 102 / 130 = x
    //
    OSStatus result = AudioUnitSetParameter (
                                             _masterEQUnit,
                                             kAUNBandEQParam_Gain + _selectedEQdBand,
                                             kAudioUnitScope_Global,
                                             0,
                                             nativeValue,
                                             0
                                             );
    
    CheckError(result,"Unable to set eq peak.");
    
    _eqPeak = eqPeak;
}
@end
