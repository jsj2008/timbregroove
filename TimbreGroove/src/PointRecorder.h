//
//  PointRecorder.h
//  TimbreGroove
//
//  Created by victor on 2/5/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PointPlayer : NSObject

-(void)reset;

// length of time to wait until calling 'next'
@property (nonatomic,readonly) NSTimeInterval duration;

// gets the 'current' pt, updates 'current'
-(GLKVector3)next;

@end

@interface PointRecorder : NSObject
-(void)reset;
-(void)add:(CGPoint)pt;

// retrieve the last point added
// useful for sending the info to a shader in update:
@property (nonatomic,readonly) GLKVector3 lastPt;

-(PointPlayer *)makePlayer;

@end

