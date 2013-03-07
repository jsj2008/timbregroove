//
//  Mixer+Parameters.h
//  TimbreGroove
//
//  Created by victor on 2/14/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "SoundSystem.h"
#import "Parameter.h"

typedef enum eqBands {
    kEQDisabled = -1,
    kEQLow,
    kEQMid,
    kEQHigh,
    
    kNUM_EQ_BANDS
} eqBands;


@interface SoundSystemParameters : NSObject

-(id)initWithSoundSystem:(SoundSystem *)ss;

@property (nonatomic,strong) NSString * selectedEQBandName;
@property (nonatomic) eqBands selectedEQBand; 
@property (nonatomic) int     selectedChannel;
@property (nonatomic) int     numChannels;

-(void)getParameters:(NSMutableDictionary *)putHere;
-(void)update:(NSTimeInterval)dt;
-(void)triggersChanged:(Scene *)scene;

+(void)configureEQ:(AudioUnit)masterEQUnit;

@end
