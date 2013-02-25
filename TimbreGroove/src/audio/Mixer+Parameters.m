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

static KnobAction _eqLowKnobMaps[] = {
    { kKnobAffect_Slide, kEQKnobCutoff,    kEasingLinear },
    { kKnobAffect_Slide, kEQKnobResonance, kEasingLinear }
};
static KnobAction _eqMidKnobMaps[] = {
    { kKnobAffect_Slide,  kEQKnobFreq,      kEasingLinear },
    { kKnobAffect_Slide,  kEQKnobPeak,      kEasingLinear },
    { kKnobAffect_Spread, kEQKnobBandwidth, kEasingLinear },
};
static KnobAction _eqHighKnobMaps[] = {
    { kKnobAffect_Slide, kEQKnobCutoff,     kEasingLinear },
    { kKnobAffect_Slide, kEQKnobResonance,  kEasingLinear }
};

static ParamDefinition _eqLowPDs[] = {
    {
        "Cutoff", // kEQKnobCutoff
        kAUNBandEQParam_Frequency,
        220, // kLowestFreq,
        kNyquistFixupNeeded,
        1000, // TODO: pick a proper default
        0, 0,
    },
    {
        "Resonance", // kEQKnobResonance -- really?? why not peak?
        kAUNBandEQParam_Bandwidth,
        0.2, // kBottomOfOctiveRange,
        4.0, // kTopOfOctiveRange,
        0.5,
        0
    }
};

static ParamDefinition _eqMidPDs[] =
{
    {
        "Center", // kEQKnobFreq
        kAUNBandEQParam_Frequency,
        kLowestFreq,
        kNyquistFixupNeeded,
        11000, // TODO: is this right?
        0
    },
    {
        "Strength", // kEQKnobPeak
        kAUNBandEQParam_Gain,
        kMinDb,
        kMaxDb,
        0.0,
        0
    },
    {
        "Width", // kEQKnobBandwidth
        kAUNBandEQParam_Bandwidth,
        kBottomOfOctiveRange,
        kTopOfOctiveRange,
        2.5, // system is 0.5
        0
    },
};

static ParamDefinition _eqHighPDs[] =
{
    {
        "Cutoff", // kEQKnobCutoff
        kAUNBandEQParam_Frequency,
        kLowestFreq,
        7000, // kNyquistFixupNeeded,
        1000, // TODO: pick a proper default
        0
    },
    {
        "Resonance", // kEQKnobResonance
        kAUNBandEQParam_Bandwidth,
        0.5, // kBottomOfOctiveRange,
        1.2, // kTopOfOctiveRange,
        0.5,
        0
    }
};

// N.B. These are layed out like eqBands enum
static EQBandInfo _bandInfos[kNUM_EQ_BANDS] = {
    {
        "Bass",
        kEQLow,
        kAUNBandEQFilterType_ResonantLowPass,
        kEQBypassON,
        2,
        _eqLowKnobMaps,
        _eqLowPDs
    },
    {
        "Mid",
        kEQMid,
        kAUNBandEQFilterType_Parametric,
        kEQBypassON,
        3,
        _eqMidKnobMaps,
        _eqMidPDs
    },
    {
        "Treble",
        kEQHigh,
        kAUNBandEQFilterType_ResonantHighPass,
        kEQBypassON,
        2,
        _eqHighKnobMaps,
        _eqHighPDs
    }
};

@implementation Mixer (Parameters)

@dynamic selectedEQBand;
@dynamic mixerOutputGain;
@dynamic bands;

-(EQBandInfo *)bands
{
    static bool _didNyquistFixup = false;
    
    if( !_didNyquistFixup )
    {
        for (int i = 0; i < kNUM_EQ_BANDS; i++ )
        {
            for (int n = 0; n < kPK_NUM_EQ_KNOBS; n++ )
            {
                if( _bandInfos[i].defs[n].max == kNyquistFixupNeeded )
                {
                    _bandInfos[i].defs[n].max = _graphSampleRate / 2.0;
                }
            }
        }
        _didNyquistFixup = true;
    }
    
    return _bandInfos;
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

-(void)turnEQBy:(NSString const *)paramName knob:(EQParamKnob)knob
{
    id sceneObj = [Global sharedInstance].scene;
    float value = [sceneObj floatForKey:(NSString *)paramName];
    [self turnEQKnobBy:value knob:knob];
}

-(float)getGlobalFloat:(NSString const *)paramName
{
    id sceneObj = [Global sharedInstance].scene;
    return [sceneObj floatForKey:(NSString *)paramName];
}

-(const EQBandInfo *)getSelectedEQBandInfo
{
    if( _selectedEQBand == kEQDisabled )
        return NULL;
    return &_bandInfos[_selectedEQBand];
}

-(void)turnEQKnobBy:(float)by knob:(EQParamKnob)knob
{
    if( _selectedEQBand == kEQDisabled )
        return;
    
    EQBandInfo * bi = &_bandInfos[_selectedEQBand];
    
    if( bi->numKnobs <= knob )
        return;
    
    ParamDefinition * def = &bi->defs[knob];
    KnobAction *      ka  = &bi->knobMap[knob];
    
    [self turnKnobBy:by pd:def easing:ka->easing band:bi->band];
    
   // NSLog(@"%s[%10s]: %05.3f %1.4f -> [%1.4f] ", bi->name, def->name, def->val, by, def->normalized );
}

-(NSDictionary *)getAUParameters
{
    return
    @{
      kParamEQFrequency: ^(float f){ [self turnEQKnobBy:f knob:0]; },
      kParamEQPeak:      ^(float f){ [self turnEQKnobBy:f knob:1]; },
      kParamEQBandwidth: ^(float f){ [self turnEQKnobBy:f knob:2]; },
      kParamMasterVolume:^(float f){ [self setMixerOutputGain:f]; }
      };
}



-(float)turnKnobBy:(float)by pd:(ParamDefinition *)def easing:(KnobEasing)easing band:(int)band
{
    AudioUnitParameterValue nativeChangeValue;
    if( easing == kEasingLinear )
    {
        nativeChangeValue = (def->max - def->min) * by;
    }
    else
    {
        // TODO: do this
        NSLog(@"missing impl for non linear knobs");
        exit(-1);
    }
    AudioUnitParameterValue newValue = def->val + nativeChangeValue;
    
    [self turnKnobTo:newValue pd:def band:band];
    
    return def->normalized;
}

-(AudioUnitParameterValue)turnKnobTo:(AudioUnitParameterValue)newValue pd:(ParamDefinition *)def band:(int)band
{
    if( newValue < def->min )
        newValue = def->min;
    else if( newValue > def->max )
        newValue = def->max;

    OSStatus result;
    result = AudioUnitSetParameter (_masterEQUnit,
                                    def->id + band,
                                    kAudioUnitScope_Global,
                                    0,
                                    newValue,
                                    0);
    
    CheckError(result, "Could not turn EQ knob");

    def->normalized = (1.0 / (def->max - def->min)) * (newValue - def->min);
    def->val = newValue;
    return newValue;
}

-(void)setSelectedEQBand:(eqBands)selectedEQBand
{
    if( _selectedEQBand == selectedEQBand )
        return;
    if( _selectedEQBand != kEQDisabled )
        _bandInfos[_selectedEQBand].byPass = kEQBypassON;
    _selectedEQBand = selectedEQBand;
    if( selectedEQBand != kEQDisabled )
        _bandInfos[_selectedEQBand].byPass = kEQBypassOFF;
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
                                        _bandInfos[i].byPass,
                                        0);
        
        CheckError(result,"Unable to set eq bypass");
    }
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

-(AudioUnitParameterValue)mixerOutputGain
{
    return _mixerOutputGain;
}

@end
