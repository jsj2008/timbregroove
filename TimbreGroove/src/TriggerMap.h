//
//  TriggerMap.h
//  TimbreGroove
//
//  Created by victor on 2/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"

typedef bool TweenDoneIndicator;
@class TriggerTween;

typedef TweenDoneIndicator (^TweenCallback)(TriggerTween *);

#ifndef SKIP_TRIGGER_DECLS
extern TweenCallback TweenLooper;
#endif

@interface TriggerTween : NSObject
-(BOOL)update:(NSTimeInterval)dt; // returns same as isDone
-(bool)isDone;
-(void)reset;
-(void)reverse;
@end

@class TriggerMap;

@protocol TriggerMapProtocol <NSObject>
-(void)queue:(TriggerTween *)tweener;
@end

@interface TriggerMap : NSObject

-(id)initWithDelegate:(id<TriggerMapProtocol>)delegate;

// Step 1. Add settable parameters
//
// @{ paramName: [Parameter ..], ...}
-(void)addParameters:(NSDictionary *)nameKeyParamValues;

// Step 2. Add mapping between trigger names and parameters
//
// @{ triggerName: paramName1, ...}
-(void)addMappings:(NSDictionary *)triggerKeyParamValues;

// Step 3. Retreive callable trigger(s)
-(FloatParamBlock)getFloatTrigger:(NSString const *)triggerName;
-(PointParamBlock)getPointTrigger:(NSString const *)triggerName;
-(IntParamBlock)getIntTrigger:(NSString const *)triggerName;
-(PointerParamBlock)getPointerTrigger:(NSString const *)triggerName;

-(FloatParamBlock)getFloatTrigger:(NSString const *)triggerName cb:(TweenCallback)cb;
-(PointParamBlock)getPointTrigger:(NSString const *)triggerName cb:(TweenCallback)cb;
-(IntParamBlock)getIntTrigger:(NSString const *)triggerName cb:(TweenCallback)cb;
-(PointerParamBlock)getPointerTrigger:(NSString const *)triggerName cb:(TweenCallback)cb;

// Step 4. Call through Trigger when appropriate

// optional:
-(void)removeMappings:(NSDictionary *)triggerKeyParamNameValues;

@end


