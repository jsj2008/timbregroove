//
//  Scene.h
//  TimbreGroove
//
//  Created by victor on 2/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Parameter.h"

@class ConfigScene;
@class GraphView;
@class Graph;
@class Audio;



@interface Scene : NSObject
+(id)defaultScene;
+(id)sceneWithName:(NSString *)name;
+(id)sceneWithConfig:(ConfigScene *)config;
-(id)initWithConfig:(ConfigScene *)config;

@property (nonatomic,strong) Graph * graph;
@property (nonatomic,strong) Audio * audio;


-(void)setParameter:(NSString const *)name
              value:(float)value
               func:(TweenFunction)f
           duration:(NSTimeInterval)duration;
-(void)tweakParameter:(NSString const *)name
                value:(float)value
                 func:(TweenFunction)f
             duration:(NSTimeInterval)duration;

-(void)setTrigger:(NSString const *)name value:(float)value;
-(void)setTrigger:(NSString const *)name point:(CGPoint)pt;
-(void)setTrigger:(NSString const *)name b:(bool)b;

-(void)tweakTrigger:(NSString const *)name by:(float)value;
-(void)tweakTrigger:(NSString const *)name byPoint:(CGPoint)pt;


-(void)queue:(Parameter *)parameter;
-(void)update:(NSTimeInterval)dt view:(GraphView *)view;

// see TriggerMap
-(bool)somebodyExpectsTrigger:(NSString const *)triggerName;

// for derivations (that don't exist yet)
-(NSDictionary *)getRuntimeConnections;
@end
