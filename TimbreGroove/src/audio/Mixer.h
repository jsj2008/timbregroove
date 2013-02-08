//
//  Mixer.h
//  TimbreGroove
//
//  Created by victor on 1/27/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface Sound : NSObject
-(OSStatus)playNote:(int)note forDuration:(NSTimeInterval)duration;
@property (nonatomic,readonly) int lowestPlayable;
@property (nonatomic,readonly) int highestPlayable;
@end

@interface Mixer : NSObject

+(Mixer *)sharedInstance;

-(Sound *)getSound:(NSString *)name;
-(NSArray *)getAllSoundNames;

@end
