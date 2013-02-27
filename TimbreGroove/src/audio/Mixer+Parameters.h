//
//  Mixer+Parameters.h
//  TimbreGroove
//
//  Created by victor on 2/14/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Mixer.h"
#import "Parameter.h"

typedef enum eqBands {
    kEQDisabled = -1,
    kEQLow,
    kEQMid,
    kEQHigh,
    
    kNUM_EQ_BANDS
} eqBands;


@interface Mixer (Parameters)

@property (nonatomic,strong) NSString * selectedEQBandName;
@property (nonatomic) eqBands selectedEQBand; 
@property (nonatomic) int     selectedChannel;
@property (nonatomic) int     numChannels;

-(NSDictionary *)getAUParameters;

-(void)configureEQ;
-(void)setupUI;
-(void)triggerExpected;


@end
