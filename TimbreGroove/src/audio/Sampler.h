//
//  Instrument.h
//  TimbreGroove
//
//  Created by victor on 2/28/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "SoundSource.h"

@class ConfigInstrument;
@class SoundSystem;

@interface Sampler : NSObject <SoundSource>

+(id)samplerWithSoundSystem:(SoundSystem *)ss;

-(void)loadSound:(ConfigInstrument *)config midi:(Midi *)midi;

@property (nonatomic,readonly) int lowestPlayable;
@property (nonatomic,readonly) int highestPlayable;
@property (nonatomic,readonly) AudioUnit sampler;
@property (nonatomic,readonly) AUNode    graphNode; // the AUGraph sees this 
@property (nonatomic) bool configured;
@property (nonatomic) MIDIPortRef     outPort;
@property (nonatomic) MIDIEndpointRef endPoint;
@property (nonatomic) int channel;
@end

