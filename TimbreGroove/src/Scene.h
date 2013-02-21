//
//  Scene.h
//  TimbreGroove
//
//  Created by victor on 2/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ConfigScene;
@class Graph;
@class Audio;


@interface Scene : NSObject
+(id)defaultScene;
+(id)sceneWithName:(NSString *)name;
+(id)sceneWithConfig:(ConfigScene *)config;
-(id)initWithConfig:(ConfigScene *)config;

@property (nonatomic,strong) Graph * graph;
@property (nonatomic,strong) Audio * audio;

-(void)setTrigger:(NSString const *)name value:(float)value;
-(void)setTrigger:(NSString const *)name point:(CGPoint)pt;
-(void)setTrigger:(NSString const *)name b:(bool)b;
-(void)setTrigger:(NSString const *)name obj:(id)obj;

-(NSDictionary *)getRuntimeConnections;
@end
