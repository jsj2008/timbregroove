//
//  TimeStretch.h
//  TimbreGroove
//
//  Created by victor on 1/24/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Sound;

@interface TimeStretch : NSObject

@property (nonatomic) bool bypass;

-(void)addToSound:(Sound *)soundObj
      timeStretch:(float)time
        semitones:(float)semitones;

@end
