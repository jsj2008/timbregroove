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
#import "EQNames.h"
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

#define kNUM_EQ_BANDS 3

typedef enum EQParamKnob {
    kEQKnobFreq,
    kEQKnobBandwidth,
    kEQKnobGain,
    
    kPK_NUM_EQ_KNOBS
} EQParamKnob;

enum EQParamKnobAliases {
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

typedef struct EQAudioParameterDefinition {
    const char * name;
    AudioParameterDefinition def;
} EQAudioParameterDefinition;

typedef struct EQBandInfo
{
    AudioUnitParameterValue filterType;
    EQAudioParameterDefinition defs[kPK_NUM_EQ_KNOBS];
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

static EQBandInfo _g_bandInfos[kNUM_EQ_BANDS] =
{
    {
        kAUNBandEQFilterType_ResonantLowPass,
        {
            {
                _kEQLowCutoff,
                {
                    kAUNBandEQParam_Frequency,
                    0.01,
                    { 220.0, kNyquistFixupNeeded }
                }
            },
            {
                _kEQLowResonance,
                {
                    kAUNBandEQParam_Bandwidth,
                    0.5,
                    { 0.2, 4.0 }
                }
            }
        }
    },
    {
        kAUNBandEQFilterType_Parametric,
        {
            {
                _kEQMidCenterFrequency,
                {
                    kAUNBandEQParam_Frequency,
                    0.5,
                    { kLowestFreq, kNyquistFixupNeeded }
                }
            },
            {
                _kEQMidBandwidth,
                {
                    kAUNBandEQParam_Bandwidth,
                    0.5,
                    { kBottomOfOctiveRange, kTopOfOctiveRange }
                }
            },
            {
                _kEQMidGain,
                {
                    kAUNBandEQParam_Gain,
                    0.0,
                    { kMinDb, kMaxDb }
                }
            }
        }
    },
    {
        kAUNBandEQFilterType_ResonantHighPass,
        {
            {
                _kEQHighCutoff,
                {
                    kAUNBandEQParam_Frequency,
                    0.3,
                    { kLowestFreq, 7000.0 /* kNyquistFixupNeeded */ }
                }
            },
            {
                _kEQHighResonance,
                {
                    kAUNBandEQParam_Bandwidth,
                    0.5,
                    { 0.5, 1.2 }
                }
            }
        }
    }
};


//////////////////////////////////////////////////////////////////
#pragma mark Parameter class decls ////////////////////

@interface AudioParameter : FloatParameter
+(id)with01AU:(AudioUnit)au
            def:(AudioParameterDefinition *)apd
             ss:(SoundSystemParameters *)ss;
+(id)withAU:(AudioUnit)au
        def:(AudioParameterDefinition *)apd
         ss:(SoundSystemParameters *)ss;
-(id)init01WithAU:(AudioUnit)au
                def:(AudioParameterDefinition *)apd
                 ss:(SoundSystemParameters *)ss;
-(id)initWithAU:(AudioUnit)au
            def:(AudioParameterDefinition *)apd
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
    pmap[kParamMasterVolume]  = [AudioParameter with01AU:_mixerUnit def:&_mixerOutVolume ss:self];
    pmap[kParamChannelVolume] = [AudioParameter with01AU:_mixerUnit def:&_mixerInVolume  ss:self];
    
    pmap[kParamChannel] = [Parameter withBlock:^(int channel) { self.selectedChannel = channel; }];

    for( int i = 0; i < kNUM_EQ_BANDS; i++ )
    {
        for( int k = 0; k < kPK_NUM_EQ_KNOBS; k++ )
        {
            EQAudioParameterDefinition * epd = &_bandInfos[i].defs[k];
            
            if( epd->name )
            {
                epd->def.band = i;
                pmap[@(epd->name)] = [AudioParameter withAU:_masterEQUnit
                                                        def:&epd->def
                                                         ss:self];
            }
        }
    }
    
    NSArray * na = @[ kParamEQLowPassEnable, kParamEQParametricEnable, kParamEQHiPassEnable ];
    [na enumerateObjectsUsingBlock:^(NSString * name, NSUInteger idx, BOOL *stop) {
        pmap[name] = [Parameter withBlock:[^(int enable) {
            OSStatus result;
            result = AudioUnitSetParameter (_masterEQUnit,
                                            kAUNBandEQParam_BypassBand + idx,
                                            kAudioUnitScope_Global,
                                            0,
                                            enable ? 0.0 : 1.0, // this is Bypass
                                            0);
            
            CheckError(result,"Unable to set eq bypass");
            NSLog(@"EQ for %d Enable: %d", idx, enable);
        } copy]];        
    }];
    
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
        _selectedChannel = 0;
        Float64 graphSampleRate  = ss.graphSampleRate;
        
        for (int i = 0; i < kNUM_EQ_BANDS; i++ )
        {
            for (int n = 0; n < kPK_NUM_EQ_KNOBS; n++ )
            {
                if( _bandInfos[i].defs[n].def.range.max == kNyquistFixupNeeded )
                {
                    _bandInfos[i].defs[n].def.range.max = graphSampleRate / 2.0;
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
    if( scene )
    {
        TriggerMap * tm = scene.triggers;
        
        _peakTrigger = [tm getFloatTrigger:kTriggerDynamicPeak];
        _holdLevelTrigger = [tm getFloatTrigger:kTriggerDynamicHold];
    }
    else
    {
        _peakTrigger = nil;
        _holdLevelTrigger = nil;
    }
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

+(id)with01AU:(AudioUnit)au
            def:(AudioParameterDefinition *)apd
             ss:(SoundSystemParameters *)ss
{
    return [[AudioParameter alloc] init01WithAU:au def:apd ss:ss];
}

+(id)withAU:(AudioUnit)au
        def:(AudioParameterDefinition *)apd
         ss:(SoundSystemParameters *)ss
{
    return [[AudioParameter alloc] initWithAU:au def:apd ss:ss];
}

-(id)init01WithAU:(AudioUnit)au
                def:(AudioParameterDefinition *)apd
                 ss:(SoundSystemParameters *)ss
{
    return [super initWith01Value:apd->defaultValue block:[ss paramTweaker:apd au:au]];
}

-(id)initWithAU:(AudioUnit)au
            def:(AudioParameterDefinition *)apd
             ss:(SoundSystemParameters *)ss
{
    return [super initWithRange:apd->range value:apd->defaultValue block:[ss paramTweaker:apd au:au]];
}
@end
