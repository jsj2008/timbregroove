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

#ifdef DEBUG_POWER
float g_last_power, g_last_radius;
#endif

//////////////////////////////////////////////////////////////////
#pragma mark consts and typedefs

const AudioUnitParameterValue kEQBypassON = 1.0;
const AudioUnitParameterValue kEQBypassOFF = 0.0;
const unsigned int kDisplayFrames = 512;

const AudioUnitParameterValue kBottomOfOctiveRange = 0.05;
const AudioUnitParameterValue kTopOfOctiveRange = 5.0;
const AudioUnitParameterValue kLowestFreq = 100.0;
const AudioUnitParameterValue kNyquistFixupNeeded = -120619.58;
const AudioUnitParameterValue kMinDb = -96.0;
const AudioUnitParameterValue kMaxDb = 24.0;

const AudioUnitElement kBusDontCare = 0;

const AudioUnitElement kBusWhatBus = -1;

#define kNUM_EQ_BANDS 3


typedef struct AudioParameterDefinition {
    AudioUnitParameterID aupid;
    FloatRange range;
    float defaultValue;  // N.B.: This is NOT a native value, it's a knob turn between 0-1
    AudioUnitScope scope;
    AudioUnitElement bus;
    int band; // if applicable
    float valueCap; 
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
    { 0.0, 1.0 },
    0.5,
    kAudioUnitScope_Output
};

static AudioParameterDefinition _g_mixerInVolume =
{
    kMultiChannelMixerParam_Volume,
    { 0.0, 1.0 },
    0.2,
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
                    { kLowestFreq, kNyquistFixupNeeded }
                }
            },
            {
                _kEQLowResonance,
                {
                    kAUNBandEQParam_Bandwidth,
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
                    { kLowestFreq, kNyquistFixupNeeded }
                }
            },
            {
                _kEQMidBandwidth,
                {
                    kAUNBandEQParam_Bandwidth,
                    { kBottomOfOctiveRange, kTopOfOctiveRange }
                }
            },
            {
                _kEQMidGain,
                {
                    kAUNBandEQParam_Gain,
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
                    { kLowestFreq, 7000.0 /* kNyquistFixupNeeded */ }
                }
            },
            {
                _kEQHighResonance,
                {
                    kAUNBandEQParam_Bandwidth,
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
+(id)withNeg11AU:(AudioUnit)au
             def:(AudioParameterDefinition *)apd
              ss:(SoundSystemParameters *)ss;
+(id)withAU:(AudioUnit)au
        def:(AudioParameterDefinition *)apd
         ss:(SoundSystemParameters *)ss;
-(id)init01AU:(AudioUnit)au
          def:(AudioParameterDefinition *)apd
           ss:(SoundSystemParameters *)ss;
-(id)initNeg11AU:(AudioUnit)au
             def:(AudioParameterDefinition *)apd
              ss:(SoundSystemParameters *)ss;
-(id)initAU:(AudioUnit)au
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
                pmap[@(epd->name)] = [AudioParameter withNeg11AU:_masterEQUnit
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
        } copy]];
    }];
}

-(id)initWithSoundSystem:(SoundSystem *)ss
{
    self = [super init];
    if( self )
    {
        _ss = ss;
        _mixerUnit = ss.mixerUnit;
        _masterEQUnit = ss.masterEQUnit;
        _selectedChannel = 0;
        
        memcpy(_bandInfos, _g_bandInfos, sizeof(_bandInfos));
        memcpy(&_mixerOutVolume, &_g_mixerOutVolume, sizeof(_mixerOutVolume));
        memcpy(&_mixerInVolume, &_g_mixerInVolume, sizeof(_mixerInVolume));
        
        _mixerOutVolume.valueCap = _mixerOutVolume.defaultValue;
        _mixerInVolume.valueCap  = _mixerInVolume.defaultValue;
        
        Float64 graphSampleRate  = ss.graphSampleRate;
        
        for (int i = 0; i < kNUM_EQ_BANDS; i++ )
        {
            for (int n = 0; n < kPK_NUM_EQ_KNOBS; n++ )
            {
                if( _bandInfos[i].defs[n].def.range.max == kNyquistFixupNeeded )
                {
                    // 0.81 for -3db roll off - WAG
                    _bandInfos[i].defs[n].def.range.max = (graphSampleRate / 2.0) * 0.81;
                }
                _bandInfos[i].defs[n].def.valueCap = _bandInfos[i].defs[n].def.defaultValue;
            }
        }        
    }
    return self;
}

-(id)paramTweaker:(AudioParameterDefinition *)apd au:(AudioUnit)au param:(FloatParameter *)param
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
        apd->valueCap = param->_value;

#if 1
        TGLog(LLAudioTweaks, @"audio tweak[%p] param: %ld scope:%ld bus:%ld band:%d -> %.4f (%.2f/%.2f)",(void *)au,
              apd->aupid,(long)apd->scope,(long)bus,apd->band,f,apd->range.min,apd->range.max);
#endif
    } copy];
}

-(float)getCurrentEQValue:(EQParamKnob)knob band:(int)band
{
    return _bandInfos[band].defs[knob].def.valueCap;
}

-(int)whichEQBandisEnabled
{
    for( int i = 0; i < kNUM_EQ_BANDS; i++ )
    {
        OSStatus result;
        AudioUnitParameterValue isBypass;
        result = AudioUnitGetParameter (_masterEQUnit,
                                        kAUNBandEQParam_BypassBand + i,
                                        kAudioUnitScope_Global,
                                        0,
                                        &isBypass);
        
        CheckError(result,"Unable to get eq bypass");
        if( !isBypass )
            return i;
    }
    
    return -1;
    
}
- (void) enableMetering:(bool)enable
{
    // turn on metering
    UInt32 meteringMode = enable ? 1 : 0;
    OSStatus err = AudioUnitSetProperty(_mixerUnit,
                                        kAudioUnitProperty_MeteringMode,
                                        kAudioUnitScope_Output,
                                        0,
                                        &meteringMode,
                                        sizeof(meteringMode) );
    CheckError(err, "Error tweaking metering mode");
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
    
    [self enableMetering:_peakTrigger || _holdLevelTrigger ];
    
}

-(void)update:(NSTimeInterval)dt
{
    OSStatus result;
    AudioUnitParameterValue value;
    
    if( _peakTrigger )
    {
        result = AudioUnitGetParameter(_mixerUnit,
                                       kMultiChannelMixerParam_PostAveragePower,
                                       kAudioUnitScope_Output,
                                       0,
                                       &value);
        CheckError(result, "Error getting peak value");
        float f = (120.0+value) / 120.0;
        _peakTrigger(f);
    }
    if( _holdLevelTrigger )
    {
        result = AudioUnitGetParameter(_mixerUnit, kMultiChannelMixerParam_PostPeakHoldLevel,
                                       kAudioUnitScope_Output, 0, &value);
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
            ss:(SoundSystemParameters *)ssp
{
    return [[AudioParameter alloc] init01AU:au def:apd ss:ssp];
}

+(id)withAU:(AudioUnit)au
        def:(AudioParameterDefinition *)apd
         ss:(SoundSystemParameters *)ssp
{
    return [[AudioParameter alloc] initAU:au def:apd ss:ssp];
}

+(id)withNeg11AU:(AudioUnit)au
             def:(AudioParameterDefinition *)apd
              ss:(SoundSystemParameters *)ssp
{
    return [[AudioParameter alloc] initNeg11AU:au def:apd ss:ssp];
}

-(id)init01AU:(AudioUnit)au
          def:(AudioParameterDefinition *)apd
           ss:(SoundSystemParameters *)ssp
{
    return [super initWith01Value:apd->valueCap block:[ssp paramTweaker:apd au:au param:self]];
}

-(id)initNeg11AU:(AudioUnit)au
              def:(AudioParameterDefinition *)apd
               ss:(SoundSystemParameters *)ssp
{
    self  = [super initWithNeg11Scaling:apd->range value:apd->valueCap block:[ssp paramTweaker:apd au:au param:self]];
    if( self )
        self.additive = false;
    return self;
}

-(id)initAU:(AudioUnit)au
        def:(AudioParameterDefinition *)apd
         ss:(SoundSystemParameters *)ssp
{
    return [super initWithScaling:apd->range value:apd->valueCap block:[ssp paramTweaker:apd au:au param:self]];
}
@end
