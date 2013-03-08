//
//  Mixer+Parameters.m
//  TimbreGroove
//
//  Created by victor on 2/14/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//
#define SKIP_MIXER_DECLS

#import "SoundSystem.h"
#import "SoundSystemParameters.h"
#import "Global.h"
#import "Names.h"
#import "Parameter.h"
#import "Scene.h"
#import "TriggerMap.h"
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

const AudioUnitElement kBusDontCare = 0;

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
    AudioUnitParameterID aupid;
    float defaultValue;  // N.B.: This is NOT a native value, it's a knob turn between 0-1
    FloatRange range;
    AudioUnitScope scope;
    AudioUnitElement bus;
    int band; // if applicable
} AudioParameterDefinition;

typedef struct EQBandInfo
{
    AudioUnitParameterValue filterType;
    AudioParameterDefinition defs[kPK_NUM_EQ_KNOBS];
} EQBandInfo;

//////////////////////////////////////////////////////////////////
#pragma mark Data defintions

static AudioParameterDefinition _g_mixerOutVolume =
{
    kMultiChannelMixerParam_Volume,
    0.5,
    { 0.0, 1.0 },
    kAudioUnitScope_Output
};

static AudioParameterDefinition _g_mixerInVolume =
{
    kMultiChannelMixerParam_Volume,
    1.0,
    { 0.0, 1.0 },
    kAudioUnitScope_Input,
    kBusWhatBus
};

// N.B. These are layed out like eqBands enum
static EQBandInfo _g_bandInfos[kNUM_EQ_BANDS] =
{
    {
        kAUNBandEQFilterType_ResonantLowPass,
        {
            {
                kAUNBandEQParam_BypassBand,
                kEQBypassON,
                { kEQBypassOFF, kEQBypassON },
                kAudioUnitScope_Global,
                kBusDontCare,
                kEQLow
            },
            {
                kAUNBandEQParam_Frequency,
                0.01,
                { 220.0, kNyquistFixupNeeded },
                kAudioUnitScope_Global,
                kBusDontCare,
                kEQLow
            },
            {
                kAUNBandEQParam_Bandwidth,
                0.5,
                { 0.2, 4.0 }, // uh, octaves (I think)
                kAudioUnitScope_Global,
                kBusDontCare,
                kEQLow
            },
            {-1}
        }
    },
    {
        kAUNBandEQFilterType_Parametric,
        {
            {
                kAUNBandEQParam_BypassBand,
                kEQBypassON,
                { kEQBypassOFF, kEQBypassON },
                kAudioUnitScope_Global,
                kBusDontCare,
                kEQMid
            },
            {
                kAUNBandEQParam_Frequency,
                0.5,
                { kLowestFreq, kNyquistFixupNeeded },
                kAudioUnitScope_Global,
                kBusDontCare,
                kEQMid
            },
            {
                kAUNBandEQParam_Bandwidth,
                0.5,
                { kBottomOfOctiveRange, kTopOfOctiveRange }, // uh, octaves (I think)
                kAudioUnitScope_Global,
                kBusDontCare,
                kEQMid
            },
            {
                kAUNBandEQParam_Gain,
                0.0,
                { kMinDb, kMaxDb },
                kAudioUnitScope_Global,
                kBusDontCare,
                kEQMid
            }            
        }
    },
    {
        kAUNBandEQFilterType_ResonantHighPass,
        {
            {
                kAUNBandEQParam_BypassBand,
                kEQBypassON,
                { kEQBypassOFF, kEQBypassON },
                kAudioUnitScope_Global,
                kBusDontCare,
                kEQHigh
            },
            {
                kAUNBandEQParam_Frequency,
                0.3,
                { kLowestFreq, 7000.0 /* kNyquistFixupNeeded */ },
                kBusDontCare,
                kAudioUnitScope_Global,
                kEQHigh
            },
            {
                kAUNBandEQParam_Bandwidth,
                0.5,
                { 0.5, 1.2 },
                kBusDontCare,
                kAudioUnitScope_Global,
                kEQHigh
            },
            {-1}
        }
    }
};


//////////////////////////////////////////////////////////////////
#pragma mark Parameter class decls ////////////////////

@interface AudioParameter : FloatParameter
+(id)withFlatAU:(AudioUnit)au
            def:(AudioParameterDefinition *)apd
             ss:(SoundSystemParameters *)ss;
+(id)withAU:(AudioUnit)au
        def:(AudioParameterDefinition *)apd
         ss:(SoundSystemParameters *)ss;
-(id)initFlatWithAU:(AudioUnit)au
                def:(AudioParameterDefinition *)apd
                 ss:(SoundSystemParameters *)ss;
-(id)initWithAU:(AudioUnit)au
            def:(AudioParameterDefinition *)apd
             ss:(SoundSystemParameters *)ss;

@end

@interface EQAudioParameter : AudioParameter
+(id)withAU:(AudioUnit)au
       knob:(EQParamKnob)knob
         ss:(SoundSystemParameters *)ss;
@end

//////////////////////////////////////////////////////////////////
#pragma mark SoundSystemParameters  ////////////////////////////////////////

@interface SoundSystemParameters() {
    EQBandInfo               _bandInfos[kNUM_EQ_BANDS];
    AudioParameterDefinition _mixerOutVolume;
    AudioParameterDefinition _mixerInVolume;
    AudioUnit                _mixerUnit;
    AudioUnit                _masterEQUnit;
    FloatParamBlock          _peakTrigger;
    FloatParamBlock          _holdLevelTrigger;
}

@end
@implementation SoundSystemParameters

-(void)getParameters:(NSMutableDictionary *)pmap
{
    pmap[kParamMasterVolume]  = [AudioParameter withFlatAU:_mixerUnit def:&_mixerOutVolume ss:self];
    pmap[kParamChannelVolume] = [AudioParameter withFlatAU:_mixerUnit def:&_mixerInVolume  ss:self];
    
    pmap[kParamChannel] = [Parameter withBlock:^(int channel) { self.selectedChannel = channel; }];
    pmap[kParamEQBand]  = [Parameter withBlock:^(int eqBand)  { self.selectedEQBand = eqBand; }];
}


-(id)initWithSoundSystem:(SoundSystem *)ss
{
    self = [super init];
    if( self )
    {
        memcpy(_bandInfos, _g_bandInfos, sizeof(_bandInfos));
        memcpy(&_mixerOutVolume, &_g_mixerOutVolume, sizeof(_mixerOutVolume));
        memcpy(&_mixerInVolume, &_g_mixerInVolume, sizeof(_mixerInVolume));
        
        _mixerUnit = ss.mixerUnit;
        _masterEQUnit = ss.masterEQUnit;
        _selectedEQBand = kEQDisabled;
        _selectedChannel = 0;
        Float64 graphSampleRate  = ss.graphSampleRate;
        
        for (int i = 0; i < kNUM_EQ_BANDS; i++ )
        {
            for (int n = 0; n < kPK_NUM_EQ_KNOBS; n++ )
            {
                if( _bandInfos[i].defs[n].range.max == kNyquistFixupNeeded )
                {
                    _bandInfos[i].defs[n].range.max = graphSampleRate / 2.0;
                }
            }
        }        
    }
    return self;
}

-(id)paramTweaker:(AudioParameterDefinition *)apd au:(AudioUnit)au
{
    return [^(float f) {
        AudioUnitElement bus = apd->bus == kBusWhatBus ? _selectedChannel : apd->bus;
        OSStatus result = AudioUnitSetParameter (au,
                                                 apd->aupid + apd->band,
                                                 apd->scope,
                                                 bus,
                                                 f,
                                                 0);
        CheckError(result, "Could not turn audio knob");
    } copy];
}

-(void)triggersChanged:(Scene *)scene
{
    TriggerMap * tm = scene.triggers;
    
    _peakTrigger = [tm getFloatTrigger:kTriggerDynamicPeak];
    _holdLevelTrigger = [tm getFloatTrigger:kTriggerDynamicHold];
}

-(void)update:(NSTimeInterval)dt
{
    OSStatus result;
    AudioUnitParameterValue value;
    
    if( _peakTrigger )
    {
        result = AudioUnitGetParameter(_mixerUnit, kMultiChannelMixerParam_PostAveragePower,
                                       kAudioUnitScope_Global, 0, &value);
        CheckError(result, "Error getting peak value");
        _peakTrigger(value);
    }
    if( _holdLevelTrigger )
    {
        result = AudioUnitGetParameter(_mixerUnit, kMultiChannelMixerParam_PostPeakHoldLevel,
                                       kAudioUnitScope_Global, 0, &value);
        CheckError(result, "Error getting peak hold value");
        _holdLevelTrigger(value);
    }
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
    _selectedEQBandName = selectedEQBandName;
    self.selectedEQBand = band;
}

-(void)setSelectedEQBand:(eqBands)selectedEQBand
{
    if( _selectedEQBand == selectedEQBand )
        return;
    if( _selectedEQBand != kEQDisabled )
        _bandInfos[_selectedEQBand].defs[kEQKnobByPass].defaultValue = kEQBypassON;
    _selectedEQBand = selectedEQBand;
    if( _selectedEQBand != kEQDisabled )
        _bandInfos[_selectedEQBand].defs[kEQKnobByPass].defaultValue = kEQBypassOFF;
    
    OSStatus result;
    
    for( int i = 0; i < kNUM_EQ_BANDS; i++ )
    {
        result = AudioUnitSetParameter (_masterEQUnit,
                                        kAUNBandEQParam_BypassBand + i,
                                        kAudioUnitScope_Global,
                                        0,
                                        kEQBypassON,
                                        0);
        
        CheckError(result,"Unable to set eq bypass");
    }
    
    
    if( _selectedEQBand != kEQDisabled )
    {
        NSDictionary * eqDict =
        @{
          kParamEQFrequency: [EQAudioParameter withAU:_masterEQUnit knob:kEQKnobFreq      ss:self],
          kParamEQBypass:    [EQAudioParameter withAU:_masterEQUnit knob:kEQKnobByPass    ss:self],
          kParamEQBandwidth: [EQAudioParameter withAU:_masterEQUnit knob:kEQKnobBandwidth ss:self]
          };

        TriggerMap * tm = [Global sharedInstance].scene.triggers;
        [tm addParameters:eqDict];
                           
        AudioParameterDefinition * apd = [self definitionForEQKnob:kEQKnobPeak];
        if( apd->aupid != -1 )
            [tm addParameters:@{kParamEQPeak:[EQAudioParameter withAU:_masterEQUnit knob:kEQKnobPeak ss:self]}];
        
    }
}

-(AudioParameterDefinition *)definitionForEQKnob:(EQParamKnob)knob
{
    return &_bandInfos[_selectedEQBand].defs[knob];
}

+(void)configureEQ:(AudioUnit)masterEQUnit
{
    OSStatus result;
    
    for( int i = 0; i < kNUM_EQ_BANDS; i++ )
    {
        result = AudioUnitSetParameter (masterEQUnit,
                                        kAUNBandEQParam_FilterType + i,
                                        kAudioUnitScope_Global,
                                        0,
                                        _g_bandInfos[i].filterType,
                                        0);
        CheckError(result,"Unable to set eq filter type.");
    }
}


@end

//////////////////////////////////////////////////////////////////
#pragma mark Property doodads impls //////////////////// ////////////////////

@implementation AudioParameter

+(id)withFlatAU:(AudioUnit)au
            def:(AudioParameterDefinition *)apd
             ss:(SoundSystemParameters *)ss
{
    return [[AudioParameter alloc] initFlatWithAU:au def:apd ss:ss];
}

+(id)withAU:(AudioUnit)au
        def:(AudioParameterDefinition *)apd
         ss:(SoundSystemParameters *)ss
{
    return [[AudioParameter alloc] initWithAU:au def:apd ss:ss];
}

-(id)initFlatWithAU:(AudioUnit)au
                def:(AudioParameterDefinition *)apd
                 ss:(SoundSystemParameters *)ss
{
    return [super initWithValue:apd->defaultValue block:[ss paramTweaker:apd au:au]];
}

-(id)initWithAU:(AudioUnit)au
            def:(AudioParameterDefinition *)apd
             ss:(SoundSystemParameters *)ss
{
    return [super initWithRange:apd->range value:apd->defaultValue block:[ss paramTweaker:apd au:au]];
}
@end

@implementation EQAudioParameter

+(id)withAU:(AudioUnit)au
       knob:(EQParamKnob)knob
         ss:(SoundSystemParameters *)ss
{
    return [[EQAudioParameter alloc] initWithAU:au knob:knob ss:ss];
}

-(id)initWithAU:(AudioUnit)au
       knob:(EQParamKnob)knob
         ss:(SoundSystemParameters *)ss

{
    AudioParameterDefinition * apd = [ss definitionForEQKnob:knob];
    return [super initWithAU:au def:apd ss:ss];
}

@end
