//
//  Mixer+Parameters.h
//  TimbreGroove
//
//  Created by victor on 2/14/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Mixer.h"

@interface Mixer (Parameters)
@property (nonatomic) AudioUnitParameterValue mixerOutputGain;
@property (nonatomic) eqBands selectedEQBand;
@property (nonatomic) AudioUnitParameterValue eqCenter;
@property (nonatomic) AudioUnitParameterValue eqPeak;  // really, don't animate
@property (nonatomic) AudioUnitParameterValue eqBandwidth;

@end
