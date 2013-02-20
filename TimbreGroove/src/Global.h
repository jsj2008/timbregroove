//
//  Global.h
//  TimbreGroove
//
//  Created by victor on 2/5/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

#define FACTORY_BPM 90.0

@class Graph;

@interface Global : NSObject
+(Global *)sharedInstance;

@property (nonatomic) float BPM;
@property (nonatomic) bool recording;
@property (nonatomic,weak) Graph * displayingGraph;

@property (nonatomic,readonly) NSTimeInterval lengthOfQuarterNote;
@property (nonatomic,readonly) NSTimeInterval lengthOf8thNote;
@property (nonatomic,readonly) NSTimeInterval lengthOf16thNote;

@property (nonatomic) float paramKnob1; // eq
@property (nonatomic) float paramKnob2; // eq
@property (nonatomic) float paramKnob3; // eq
@property (nonatomic) float paramKnob4; // volume
@property (nonatomic) float paramKnob5;
@property (nonatomic) float paramKnob6;
@property (nonatomic) float paramKnob7;
@property (nonatomic) float paramKnob8;

@property (nonatomic) CGPoint paramPad1; // tap
@property (nonatomic) CGPoint paramPad2; // cursor direction (1 finger)
@property (nonatomic) CGPoint paramPad3; // cursor direction (2 finger)
@property (nonatomic) CGPoint paramPad4;
@property (nonatomic) CGPoint paramPad5;
@property (nonatomic) CGPoint paramPad6;
@property (nonatomic) CGPoint paramPad7;
@property (nonatomic) CGPoint paramPad8;

@property (nonatomic) CGPoint windowTap;
@end
