//
//  Scene.h
//  TimbreGroove
//
//  Created by victor on 2/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Parameter.h"
#import "TriggerMap.h"

@class ConfigScene;
@class GraphView;
@class Graph;
@class Audio;
@class Scene;

/*
 Scene modules should implement:
-(void)getParameters:(NSMutableDictionary)putHere;
-(void)triggersChanged:(Scene *)scene;
-(void)update:(NSTimeInterval)dt;
-(void)play;
-(void)pause;
*/

@interface Scene : NSObject<TriggerMapProtocol>

+(id)defaultScene;
+(id)sceneWithName:(NSString *)name;
+(id)systemSceneWithName:(NSString *)name;
+(id)sceneWithConfig:(ConfigScene *)config;
-(id)initWithConfig:(ConfigScene *)config;

-(void)decomission;

@property (nonatomic,strong) Graph * graph;
@property (nonatomic,strong) Audio * audio;
@property (nonatomic,strong) TriggerMap * triggers;

-(void)pause;
-(void)play;

- (void)getSettings:(NSMutableArray *)putHere;

- (void)update:(NSTimeInterval)dt view:(GraphView *)view;

// For dynamic/modal operations (e.g. recording)
-(void)addTriggers:(NSDictionary *)triggerKeyParamNameValue;
-(void)removeTriggers:(NSDictionary *)triggerKeyParamNameValue;

@end
