//
//  Mixer+Parameters.m
//  TimbreGroove
//
//  Created by victor on 2/14/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//
#define SKIP_MIXER_DECLS

#import "SoundSystem.h"
#import "SoundSystem+Parameters.h"
#import "Global.h"
#import "Names.h"
#import "Parameter.h"
#import "Scene.h"
#import "ConfigNames.h"

//////////////////////////////////////////////////////////////////
#pragma mark consts and typedefs

const AudioUnitParameterValue kEQBypassON = 1.0;
const AudioUnitParameterValue kEQBypassOFF = 0.0;
const unsigned int kDisplayFrames = 512;

const AudioUnitParameterValue kBottomOfOctiveRange = 0.05;
const AudioUnitParameterValue kTopOfOctiveRange = 5.0;
const AudioUnitParameterValue kLowestFreq = 20.0;
const AudioUnitParameterValue kNyquistFixupNeeded = -120619.58;
const AudioUnitParameterValue kMinDb = -96.0;
const AudioUnitParameterValue kMaxDb = 24.0;

const AudioUnitElement kBusWhatBus = -1;

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
    AudioUnitElement bus;
}AudioParameterDefinition;

typedef struct EQBandInfo
{
    AudioUnitParameterValue filterType;
    AudioParameterDefinition defs[kPK_NUM_EQ_KNOBS];
} EQBandInfo;

//////////////////////////////////////////////////////////////////
#pragma mark Data defintions

static ParameterDefintion _channels =
{
    TG_INT, { 0 }, { 0 }, { 0 /* set in setNumChannels */ }
};

static ParameterDefintion _eqBand =
{
    TG_INT, { .i = kEQDisabled } , { .i = kEQDisabled }, { .i = kNUM_EQ_BANDS }
};


static AudioParameterDefinition _mixerOutVolume =
{
    {   TG_FLOAT,
        { 0.5 }, { 0.0 }, { 1.0 },
        kTweenEaseInSine, 0.1
    },
    kMultiChannelMixerParam_Volume, 0, kAudioUnitScope_Output
};

static AudioParameterDefinition _mixerInVolume =
{
    {   TG_FLOAT,
        { 1.0 }, { 0.0 }, { 1.0 },
        kTweenEaseInSine, 0.5
    },
    kMultiChannelMixerParam_Volume, 0, kAudioUnitScope_Input, kBusWhatBus
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
                    { 0.0 }, { kMinDb }, { kMaxDb },
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
                    { 1000.0 }, { kLowestFreq }, { 7000.0 /* kNyquistFixupNeeded */ },
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

//////////////////////////////////////////////////////////////////
#pragma mark Parameter class decls ////////////////////

@interface MixerParameter : Parameter {
    @protected
    __weak SoundSystem * _mixer;
    bool _debugDump;
}
@property (nonatomic,weak) SoundSystem * mixer;
@end

@interface MixerPropertyParameter : MixerParameter {
    NSString * _propName;
}
-(id)initWithDef:(ParameterDefintion *)def name:(NSString const *)name prop:(NSString *)propName;
@end


@interface AudioParameter : MixerParameter {
    AudioUnit _au;
}
-(id)initWithAU:(AudioUnit)au def:(AudioParameterDefinition *)apd name:(NSString const *)name;
@property (nonatomic,weak) SoundSystem * mixer;
@end

@interface EQAudioParameter : AudioParameter {
    EQParamKnob _knob;
}
-(id)initWithAU:(AudioUnit)au knob:(EQParamKnob)knob name:(NSString const *)name;
@end

//////////////////////////////////////////////////////////////////
#pragma mark Mixer (!) //////////////////////////////////////// 

@implementation SoundSystem (Parameters)

@dynamic selectedEQBandName;
@dynamic selectedEQBand;
@dynamic selectedChannel;
@dynamic numChannels;

-(void)getParameters:(NSMutableDictionary *)pmap
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
    
    for( MixerParameter * mp in _auParameters )
    {
        mp.mixer = self;
        pmap[mp.parameterName] = mp.myParamBlock;
    }
}


-(void)setupUI
{
    _selectedEQBand = kEQDisabled;
    _selectedChannel = 0;

    _auParameters = @[
                      [[EQAudioParameter alloc] initWithAU:_masterEQUnit knob:kEQKnobFreq name:kParamEQFrequency],
                      [[EQAudioParameter alloc] initWithAU:_masterEQUnit knob:kEQKnobPeak name:kParamEQPeak],
                      [[EQAudioParameter alloc] initWithAU:_masterEQUnit knob:kEQKnobBandwidth name:kParamEQBandwidth],
                      [[EQAudioParameter alloc] initWithAU:_masterEQUnit knob:kEQKnobByPass name:kParamEQBypass],
                      [[AudioParameter alloc] initWithAU:_mixerUnit def:&_mixerOutVolume name:kParamMasterVolume],
                      [[AudioParameter alloc] initWithAU:_mixerUnit def:&_mixerInVolume name:kParamChannelVolume],
                      [[MixerPropertyParameter alloc] initWithDef:&_eqBand name:kParamEQBand prop:@"selectedEQBand"],
                      [[MixerPropertyParameter alloc] initWithDef:&_channels name:kParamChannel prop:@"selectedChannel"]
                      ];
    
    [[Global sharedInstance] addObserver:self
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
        if( [scene somebodyExpectsTrigger:kTriggerAudioFrame] )
            _expectedTriggerFlags |= kExpectsCapture;
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

-(void)setParameterValue:(AudioUnitParameterValue)value
                     apd:(AudioParameterDefinition *)apd
                      au:(AudioUnit)au
{
    OSStatus result;
    AudioUnitElement bus = apd->bus == kBusWhatBus ? _selectedChannel : apd->bus;
    result = AudioUnitSetParameter (au,
                                    apd->id + apd->band,
                                    apd->scope,
                                    bus,
                                    value,
                                    0);
    
    CheckError(result, "Could not turn audio knob");
}


-(void)setSelectedChannel:(int)selectedChannel
{
    _selectedChannel = selectedChannel;
}

-(int)selectedChannel
{
    return _selectedChannel;
}

-(void)setNumChannels:(int)numChannels
{
    _numChannels = numChannels;
    _channels.max.i = numChannels - 1;
}

-(int)numChannels
{
    return _numChannels;
}

-(void)setSelectedEQBandName:(NSString *)selectedEQBandName
{
    eqBands band;
    if( [kConfigEQBandLowPass isEqualToString:selectedEQBandName] )
        band = kEQLow;
    else if( [kConfigEQBandParametric isEqualToString:selectedEQBandName])
        band = kEQMid;
    else if( [kConfigEQBandHighPass isEqualToString:selectedEQBandName])
        band = kEQHigh;
    self.selectedEQBand = band;
}

-(NSString *)selectedEQBandName
{
    return _selectedEQBandName;
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
}
@end

//////////////////////////////////////////////////////////////////
#pragma mark Property doodads impls //////////////////// ////////////////////

@implementation MixerParameter
@end

@implementation MixerPropertyParameter

-(id)initWithDef:(ParameterDefintion *)def name:(NSString const *)name prop:(NSString *)propName
{
    self = [super initWithDef:def valueNotify:nil];
    if( self )
    {
        _propName = propName;
        self.parameterName = name;
    }
    return self;
}

-(void)setMixer:(SoundSystem *)mixer
{
    __block MixerPropertyParameter * me = self;
    self.valueNotify = ^{
        [mixer setValue:@(me->_pd->currentValue.i) forKey:me->_propName];
    };
    
    [mixer setValue:@(_pd->def.i) forKey:me->_propName];
}
@end

@implementation AudioParameter

-(id)initWithAU:(AudioUnit)au def:(AudioParameterDefinition *)apd name:(NSString const *)name
{
    self = [super initWithDef:&apd->pd valueNotify:nil];
    if( self )
    {
        self.parameterName = name;
        _au = au;
    }
    return self;
}

-(void)setMixer:(SoundSystem *)mixer
{
    _mixer = mixer;
    __block AudioParameter * me = self;
    self.valueNotify = ^{
        [mixer setParameterValue:me->_pd->currentValue.f apd:(AudioParameterDefinition *)me->_pd au:me->_au];
        if( me->_debugDump )
            NSLog(@"audio param[%@]: %f", me.parameterName, me->_pd->currentValue.f);
    };
    
    [mixer setParameterValue:_pd->def.f apd:(AudioParameterDefinition *)_pd au:_au];
}

@end

@implementation EQAudioParameter

-(id)initWithAU:(AudioUnit)au knob:(EQParamKnob)knob name:(NSString const *)name;
{
    self = [super initWithAU:au def:nil name:name];
    if( self )
    {
        _knob = knob;
    }
    return self;
}

-(void)setMixer:(SoundSystem *)mixer
{
    _mixer = mixer;
    __block EQAudioParameter * me = self;
    self.valueNotify = ^{
        eqBands band = mixer.selectedEQBand;
        if( band == kEQDisabled )
            return;
        me->_pd = (ParameterDefintion *)&_bandInfos[band].defs[me->_knob];
        [mixer setParameterValue:me->_pd->currentValue.f apd:(AudioParameterDefinition *)me->_pd au:me->_au];
        if( me->_debugDump )
            NSLog(@"EQ audio param[%@]: %f", me.parameterName, me->_pd->currentValue.f);
    };

    for( int i = 0; i < sizeof(_bandInfos)/sizeof(_bandInfos[i]); i++ )
    {
        ParameterDefintion * pd = (ParameterDefintion *)&_bandInfos[i].defs[_knob];
        [mixer setParameterValue:pd->def.f apd:(AudioParameterDefinition *)pd au:_au];
        self.definition = pd;
        [self calcScale];
    }
}

@end
