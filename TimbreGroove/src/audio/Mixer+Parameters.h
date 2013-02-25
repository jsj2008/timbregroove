//
//  Mixer+Parameters.h
//  TimbreGroove
//
//  Created by victor on 2/14/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Mixer.h"


typedef enum eqBands {
    kEQDisabled = -1,
    kEQLow,
    kEQMid,
    kEQHigh,
    
    kNUM_EQ_BANDS
} eqBands;

typedef enum EQParamKnob {
    kEQKnobFreq,
    kEQKnobCutoff = kEQKnobFreq,
    kEQKnobBandwidth,
    kEQKnobResonance = kEQKnobBandwidth,
    kEQKnobGain,
    kEQKnobPeak = kEQKnobGain,
    
    kPK_NUM_EQ_KNOBS
} EQParamKnob;


typedef enum KnobEasing {
    kEasingLinear,
    kEasingExp, // explosive growth at end
    kEasingLog, // explosive growth at start
} KnobEasing;

typedef enum KnobTurnAffect {
    kKnobAffect_Slide,
    kKnobAffect_Spread, //
    kKnobAffect_Switch,
} KnobTurnAffect; // sic!

typedef struct KnobAction {
    KnobTurnAffect moveType;
    int            knob;
    KnobEasing     easing;
} KnobAction;

typedef struct ParamDefinition
{
    const char *            name;
    AudioUnitParameterID    id;
    AudioUnitParameterValue min;
    AudioUnitParameterValue max;
    AudioUnitParameterValue def;
    AudioUnitParameterValue val;
    float                   normalized;
} ParamDefinition;


typedef struct EQBandInfo
{
    const char *            name;
    eqBands                 band;
    AudioUnitParameterValue filterType;
    AudioUnitParameterValue byPass;
    int                     numKnobs;
    KnobAction *            knobMap;
    ParamDefinition *       defs;
} EQBandInfo;


@interface Mixer (Parameters)

// by is assumed to be -1.0 <= by <= 1.0
// band is 0 for all non-eq AUs
-(float)turnKnobBy:(float)by pd:(ParamDefinition *)pd easing:(KnobEasing)easing band:(int)band;

// newValue will be clamped by ParamDefinition.min < newValue < ParamDefinition.max
// band is 0 for all non-eq AUs
-(AudioUnitParameterValue)turnKnobTo:(AudioUnitParameterValue)newValue pd:(ParamDefinition *)def band:(int)band;

-(const EQBandInfo *)getSelectedEQBandInfo;

@property (nonatomic) AudioUnitParameterValue mixerOutputGain;
@property (nonatomic) eqBands selectedEQBand; // also calls enabledSelectedEQBand
@property (nonatomic) EQBandInfo * bands;

-(NSDictionary *)getAUParameters;

-(void)enableSelectedEQBand;
-(void)setupUI;
-(void)triggerExpected;

@end
