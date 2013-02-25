//
//  Mixer+Parameters.m
//  TimbreGroove
//
//  Created by victor on 2/14/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//
#define SKIP_MIXER_DECLS

#import "Mixer.h"
#import "Mixer+Parameters.h"
#import "Global.h"
#import "Names.h"
#import "Parameter.h"
#import "Scene.h"

const AudioUnitParameterValue kEQBypassON = 1;
const AudioUnitParameterValue kEQBypassOFF = 0;
const unsigned int kDisplayFrames = 512;

const AudioUnitParameterValue kBottomOfOctiveRange = 0.05;
const AudioUnitParameterValue kTopOfOctiveRange = 5.0;
const AudioUnitParameterValue kLowestFreq = 20.0;
const AudioUnitParameterValue kNyquistFixupNeeded = -120619.58;
const AudioUnitParameterValue kMinDb = -96.0;
const AudioUnitParameterValue kMaxDb = 24.0;

typedef enum EQParamKnob {
    kEQKnobByPass,
    kEQKnobFreq,
    kEQKnobBandwidth,
    kEQKnobGain,
    
    kPK_NUM_EQ_KNOBS
} EQParamKnob;

enum EQParamKnobAliases {
    kEQKnobBypass    = kEQKnobByPass,
    kEQKnobCutoff    = kEQKnobFreq,
    kEQKnobResonance = kEQKnobBandwidth,
    kEQKnobPeak      = kEQKnobGain
};

typedef struct AudioParameterDefinition {
    ParameterDefintion pd;
    AudioUnitParameterID id;
    int band; // if applicable
    AudioUnitScope scope;
    int bus;
}AudioParameterDefinition;

typedef struct EQBandInfo
{
    AudioUnitParameterValue filterType;
    AudioParameterDefinition defs[kPK_NUM_EQ_KNOBS];
} EQBandInfo;


static AudioParameterDefinition _mixerOutVolume =
{
    {   TG_FLOAT,
        { 0.5 }, { 0 }, { 1 },
        kTweenEaseInSine, 0.1
    },
    kMultiChannelMixerParam_Volume, 0, kAudioUnitScope_Output
};

static AudioParameterDefinition _mixerInVolume =
{
    {   TG_FLOAT,
        { 1.0 }, { 0 }, { 1 },
        kTweenEaseInSine, 0.5
    },
    kMultiChannelMixerParam_Volume, 0, kAudioUnitScope_Input
};

// N.B. These are layed out like eqBands enum
static EQBandInfo _bandInfos[kNUM_EQ_BANDS] =
{
    {
        kAUNBandEQFilterType_ResonantLowPass,
        {
            {
                {   TG_BOOL_FLOAT,
                    { kEQBypassON }, { kEQBypassOFF }, { kEQBypassON }
                },
                kAUNBandEQParam_BypassBand, kEQLow, kAudioUnitScope_Global
            },
            {
                {   TG_FLOAT,
                    { 1000.0 }, { 220.0 }, { kNyquistFixupNeeded },
                    kTweenEaseInSine, 0.2,
                    kParamFlagPerformScaling | kParamFlagsAdditiveValues
                },
                kAUNBandEQParam_Frequency, kEQLow, kAudioUnitScope_Global
            },
            {
                {   TG_FLOAT,
                    { 0.5 }, { 0.2 }, { 4.0 }, // uh, octaves (I think)
                    kTweenEaseInSine, 0.2,
                    kParamFlagPerformScaling | kParamFlagsAdditiveValues
                },
                kAUNBandEQParam_Bandwidth, kEQLow, kAudioUnitScope_Global
            },
            {
                {-1}
            }
            
        }
    },
    {
        kAUNBandEQFilterType_Parametric,
        {
            {
                {   TG_BOOL_FLOAT,
                    { kEQBypassON }, { kEQBypassOFF }, { kEQBypassON }
                },
                kAUNBandEQParam_BypassBand, kEQMid, kAudioUnitScope_Global
            },
            {
                {   TG_FLOAT,
                    { 11000.0 }, { kLowestFreq }, { kNyquistFixupNeeded },
                    kTweenEaseInSine, 0.2,
                    kParamFlagPerformScaling | kParamFlagsAdditiveValues
                },
                kAUNBandEQParam_Frequency, kEQMid, kAudioUnitScope_Global
            },
            {
                {   TG_FLOAT,
                    { 2.5 }, { kBottomOfOctiveRange }, { kTopOfOctiveRange },
                    kTweenEaseInSine, 0.2,
                    kParamFlagPerformScaling | kParamFlagsAdditiveValues
                },
                kAUNBandEQParam_Bandwidth, kEQMid, kAudioUnitScope_Global
            },
            {
                {   TG_FLOAT,
                    { 0 }, { kMinDb }, { kMaxDb },
                    kTweenEaseInSine, 0.2,
                    kParamFlagPerformScaling | kParamFlagsAdditiveValues
                },
                kAUNBandEQParam_Gain, kEQMid, kAudioUnitScope_Global
            }
        }
    },
    {
        kAUNBandEQFilterType_ResonantHighPass,
        {
            {
                {   TG_BOOL_FLOAT,
                    { kEQBypassON }, { kEQBypassOFF }, { kEQBypassON }
                },
                kAUNBandEQParam_BypassBand, kEQHigh, kAudioUnitScope_Global
            },
            {
                {   TG_FLOAT,
                    { 1000.0 }, { kLowestFreq }, { 7000 /* kNyquistFixupNeeded */ },
                    kTweenEaseInSine, 0.2,
                    kParamFlagPerformScaling | kParamFlagsAdditiveValues
                },
                kAUNBandEQParam_Frequency, kEQHigh, kAudioUnitScope_Global
            },
            {
                {   TG_FLOAT,
                    { 0.5 }, { 0.5 }, { 1.2 },
                    kTweenEaseInSine, 0.2,
                    kParamFlagPerformScaling | kParamFlagsAdditiveValues
                },
                kAUNBandEQParam_Bandwidth, kEQHigh, kAudioUnitScope_Global
            },
            {
                {-1}
            }
        }
    }
};

@interface AudioParameterBase : Parameter {
@protected
    ParamBlock _paramBlock;
    AudioUnit _au;
}

@property (nonatomic,strong) ParamBlock paramBlock;
@end

@implementation AudioParameterBase

-(id)initWithAudioUnit:(AudioUnit)au andDef:(AudioParameterDefinition *)apd
{
    self = [super initWithDef:&apd->pd];
    if( self )
    {
        _au = au;        
    }
    return self;
    
}


-(void)update:(NSTimeInterval)dt
{
    [super update:dt];
    AudioParameterDefinition * apd = (AudioParameterDefinition *)_pd;
    OSStatus result;
    result = AudioUnitSetParameter (_au,
                                    apd->id + apd->band,
                                    apd->scope,
                                    apd->bus,
                                    apd->pd.currentValue.f,
                                    0);
    
    CheckError(result, "Could not turn audio knob");
}
@end

@interface AudioParameter : AudioParameterBase

@end

@implementation AudioParameter

-(id)initWithAudioUnit:(AudioUnit)au andDef:(AudioParameterDefinition *)apd
{
    self = [super initWithAudioUnit:au andDef:apd];
    if( self )
    {
        OSStatus result;
        result = AudioUnitSetParameter (_au,
                                        apd->id + apd->band,
                                        apd->scope,
                                        apd->bus,
                                        apd->pd.def.f,
                                        0);
        
        CheckError(result, "Could not turn audio knob to default");
        
        __weak Parameter * me = self;
        _paramBlock = ^(NSValue * f){
            [me setValueTo:f];
        };
    }
    return self;
}

@end


@interface EQParameter : AudioParameterBase
-(id)initWithAU:(AudioUnit)au andKnob:(EQParamKnob)knob andMixer:(Mixer *)mixer;
@end


@implementation EQParameter

-(id)initWithAU:(AudioUnit)au andKnob:(EQParamKnob)knob andMixer:(Mixer *)mixer;
{
    self = [super initWithAudioUnit:au andDef:nil];
    if( self )
    {
        OSStatus result;
        for( int i = 0; i < kNUM_EQ_BANDS; i++ )
        {
            AudioParameterDefinition * apd = &_bandInfos[i].defs[knob];
            result = AudioUnitSetParameter (au,
                                            apd->id + apd->band,
                                            apd->scope,
                                            apd->bus,
                                            apd->pd.def.f,
                                            0);
            
            CheckError(result, "Could not turn audio knob");
        }
        
        __weak EQParameter * me = self;
        ParameterDefintion **pp = &_pd;
        _paramBlock = ^(NSValue * f){
            eqBands band = mixer.selectedEQBand;
            *pp = &_bandInfos[band].defs[knob].pd;
            [me setValueTo:f];
        };
    }
    return self;
}

@end

@implementation Mixer (Parameters)

@dynamic selectedEQBand;
@dynamic selectedChannel;

-(NSDictionary *)getAUParameters
{
    for (int i = 0; i < kNUM_EQ_BANDS; i++ )
    {
        for (int n = 0; n < kPK_NUM_EQ_KNOBS; n++ )
        {
            if( _bandInfos[i].defs[n].pd.max.f == kNyquistFixupNeeded )
            {
                _bandInfos[i].defs[n].pd.max.f = _graphSampleRate / 2.0;
            }
        }
    }
    
    NSMutableDictionary * pmap = [NSMutableDictionary new];
    
    pmap[kParamEQFrequency] = [[EQParameter alloc] initWithAU:_mixerUnit andKnob:kEQKnobFreq andMixer:self].paramBlock;
    pmap[kParamEQPeak]      = [[EQParameter alloc] initWithAU:_mixerUnit andKnob:kEQKnobPeak andMixer:self].paramBlock;
    pmap[kParamEQBandwidth] = [[EQParameter alloc] initWithAU:_mixerUnit andKnob:kEQKnobBandwidth andMixer:self].paramBlock;
    pmap[kParamEQBypass]    = [[EQParameter alloc] initWithAU:_mixerUnit andKnob:kEQKnobByPass andMixer:self].paramBlock;
    
    pmap[kParamMasterVolume]= [[AudioParameter alloc] initWithAudioUnit:_mixerUnit andDef:&_mixerOutVolume].paramBlock;
    
    pmap[kParamEQBand] = ^(NSValue *nsv){
        int band = [((NSNumber *)nsv) intValue];
        if( band >= kNUM_EQ_BANDS || band < kEQDisabled )
            band = kEQDisabled;
        [self setSelectedEQBand:band];
    };
    
    pmap[kParamChannel] = ^(NSValue *nsv){
        int channel = [((NSNumber *)nsv) intValue];
        [self setSelectedChannel:channel];
    };
    
    return pmap;
}


-(void)setupUI
{
    _selectedEQBand = kEQDisabled;
    Global * g = [Global sharedInstance];
    [g addObserver:self
        forKeyPath:(NSString *)kGlobalScene
           options:NSKeyValueObservingOptionNew
           context:NULL];    
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if( [kGlobalScene isEqualToString:keyPath] )
    {
        _expectedTriggerFlags = 0;
        Scene * scene = [Global sharedInstance].scene;
        if( [scene somebodyExpectsTrigger:kTriggerDynamicPeak] )
            _expectedTriggerFlags = kExpectsPeak;
        if( [scene somebodyExpectsTrigger:kTriggerDynamicHold] )
            _expectedTriggerFlags |= kExpectsPeakHold;
    }
}

-(void)triggerExpected
{
    OSStatus result;
    AudioUnitParameterValue value;
    Scene * scene = [Global sharedInstance].scene;
    
    if( (_expectedTriggerFlags & kExpectsPeak) != 0 )
    {
        result = AudioUnitGetParameter(_mixerUnit, kMultiChannelMixerParam_PostAveragePower,
                                       kAudioUnitScope_Global, 0, &value);
        CheckError(result, "Error getting peak value");
        [scene setTrigger:kTriggerDynamicPeak value:value];
    }
    if( (_expectedTriggerFlags & kExpectsPeakHold) != 0 )
    {
        result = AudioUnitGetParameter(_mixerUnit, kMultiChannelMixerParam_PostPeakHoldLevel,
                                       kAudioUnitScope_Global, 0, &value);
        CheckError(result, "Error getting peak hold value");
        [scene setTrigger:kTriggerDynamicHold value:value];
    }
}


-(void)setSelectedChannel:(int)selectedChannel
{
    _selectedChannel = selectedChannel;
}

-(int)selectedChannel
{
    return _selectedChannel;
}

-(void)setSelectedEQBand:(eqBands)selectedEQBand
{
    if( _selectedEQBand == selectedEQBand )
        return;
    if( _selectedEQBand != kEQDisabled )
        _bandInfos[_selectedEQBand].defs[kEQKnobByPass].pd.currentValue.f = kEQBypassON;
    _selectedEQBand = selectedEQBand;
    if( selectedEQBand != kEQDisabled )
        _bandInfos[_selectedEQBand].defs[kEQKnobByPass].pd.currentValue.f = kEQBypassOFF;
    [self enableSelectedEQBand];
}

-(eqBands)selectedEQBand
{
    return _selectedEQBand;
}

-(void)enableSelectedEQBand
{
    OSStatus result;
    
    for( int i = 0; i < kNUM_EQ_BANDS; i++ )
    {
        result = AudioUnitSetParameter (_masterEQUnit,
                                        kAUNBandEQParam_BypassBand + i,
                                        kAudioUnitScope_Global,
                                        0,
                                        _bandInfos[i].defs[kEQKnobByPass].pd.currentValue.f,
                                        0);
        
        CheckError(result,"Unable to set eq bypass");
    }
}

-(void)configureEQ
{
    OSStatus result;
    
    for( int i = 0; i < kNUM_EQ_BANDS; i++ )
    {
        result = AudioUnitSetParameter (_masterEQUnit,
                                        kAUNBandEQParam_FilterType + i,
                                        kAudioUnitScope_Global,
                                        0,
                                        _bandInfos[i].filterType,
                                        0);
        CheckError(result,"Unable to set eq filter type.");
    }
    
    [self enableSelectedEQBand];    
}
@end
