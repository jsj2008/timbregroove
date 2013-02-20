//
//  Mixer+Parameters.m
//  TimbreGroove
//
//  Created by victor on 2/14/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//
#define TimbreGroove_MixerParamConsts_h // prevent including here

#import "Mixer.h"
#import "Mixer+Parameters.h"
#import "Global.h"


NSString * const kParamKnob1 = @"paramKnob1";
NSString * const kParamKnob2 = @"paramKnob2";
NSString * const kParamKnob3 = @"paramKnob3";
NSString * const kParamKnob4 = @"paramKnob4";
NSString * const kParamKnob5 = @"paramKnob5";
NSString * const kParamKnob6 = @"paramKnob6";
NSString * const kParamKnob7 = @"paramKnob7";
NSString * const kParamKnob8 = @"paramKnob8";

NSString * const kParamPad1 = @"paramPad1";
NSString * const kParamPad2 = @"paramPad2";
NSString * const kParamPad3 = @"paramPad3";
NSString * const kParamPad4 = @"paramPad4";
NSString * const kParamPad5 = @"paramPad5";
NSString * const kParamPad6 = @"paramPad6";
NSString * const kParamPad7 = @"paramPad7";
NSString * const kParamPad8 = @"paramPad8";

const AudioUnitParameterValue kEQBypassON = 1;
const AudioUnitParameterValue kEQBypassOFF = 0;

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
        kEQBypassOFF,
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
    _globalsParamMap = @{kParamKnob1: ^{ [self turnEQKnobBy:[Global sharedInstance].paramKnob1 knob:0]; },
                         kParamKnob2: ^{ [self turnEQKnobBy:[Global sharedInstance].paramKnob2 knob:1]; },
                         kParamKnob3: ^{ [self turnEQKnobBy:[Global sharedInstance].paramKnob3 knob:2]; },
                         kParamKnob4: ^{ [self setMixerOutputGain:[Global sharedInstance].paramKnob4]; }
                         };
    
    for( NSString * propName in _globalsParamMap )
    {
        [[Global sharedInstance] addObserver:self
                                  forKeyPath:propName
                                     options:NSKeyValueObservingOptionNew
                                     context:NULL];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    for (NSString * key in _globalsParamMap)
        if( [keyPath isEqualToString:key] )
        {
            void (^ dispatchBlock)() = _globalsParamMap[key];
            dispatchBlock();
        }
}


-(const EQBandInfo *)getSelectedEQBandInfo
{
    return &_bandInfos[_selectedEQBand];
}

-(void)turnEQKnobBy:(float)by knob:(EQParamKnob)knob
{
    EQBandInfo * bi = &_bandInfos[_selectedEQBand];
    
    if( bi->numKnobs <= knob )
        return;
    
    ParamDefinition * def = &bi->defs[knob];
    KnobAction *      ka  = &bi->knobMap[knob];
    
    [self turnKnobBy:by pd:def easing:ka->easing band:bi->band];
    
   // NSLog(@"%s[%10s]: %05.3f %1.4f -> [%1.4f] ", bi->name, def->name, def->val, by, def->normalized );
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
    _bandInfos[_selectedEQBand].byPass = kEQBypassON;
    _selectedEQBand = selectedEQBand;
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
