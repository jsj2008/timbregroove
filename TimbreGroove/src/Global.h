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

@end
