//
//  Mixer+Parameters.h
//  TimbreGroove
//
//  Created by victor on 2/14/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "SoundSystem.h"
#import "Parameter.h"

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

@interface SoundSystemParameters : NSObject

-(id)initWithSoundSystem:(SoundSystem *)ss;

@property (nonatomic) int     selectedChannel;
@property (nonatomic) int     numChannels;
@property (nonatomic,weak) SoundSystem * ss;

-(void)getParameters:(NSMutableDictionary *)putHere;
-(void)update:(NSTimeInterval)dt;
-(void)triggersChanged:(Scene *)scene;

+(void)configureEQ:(AudioUnit)masterEQUnit;

-(float)getCurrentEQValue:(EQParamKnob)knob band:(int)band;
-(int)whichEQBandisEnabled;

@end
