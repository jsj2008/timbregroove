//
//  Scene.m
//  TimbreGroove
//
//  Created by victor on 2/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Scene.h"
#import "TriggerMap.h"
#import "Config.h"
#import "Graph.h"
#import "GraphView.h"
#import "Global.h"
#import "Audio.h"
#import "Parameter.h"

@interface Scene () {
    ConfigScene * _config;
    NSMutableArray * _tweenQueue;
    bool _started;
}

@end
@implementation Scene

+(id)defaultScene
{
    ConfigScene * config = [[Config sharedInstance] defaultScene];
    return [[Scene alloc] initWithConfig:config];
}

+(id)sceneWithName:(NSString *)name
{
    ConfigScene * config = [[Config sharedInstance] getScene:name];
    return [[Scene alloc] initWithConfig:config];
}

+(id)sceneWithConfig:(ConfigScene *)config
{
    return [[Scene alloc] initWithConfig:config];
}

-(id)initWithConfig:(ConfigScene *)config
{
    self = [super init];
    if (self) {        
        _tweenQueue = [NSMutableArray new];

        _triggers = [[TriggerMap alloc] initWithDelegate:self];
        _config = config;
        
        _audio = [Audio audioFromConfig:config.audioElement withScene:self];
        
        _graph = [Graph new];
        Global * g = [Global sharedInstance];
        [_graph loadFromConfig:config.graphicElement andViewSize:g.graphViewSize];

        NSMutableDictionary * params = [NSMutableDictionary new];
        [_graph getParameters:params];
        [_audio getParameters:params];
        [_triggers addParameters:params];

        [config.connections apply:^(id map) { [_triggers addMappings:map];}];
        [_graph triggersChanged:self];
        [_audio triggersChanged:self];
        
        [_triggers addMappings:[self getRuntimeConnections]];
    }
    return self;
}

-(void)addTriggers:(NSDictionary *)triggerKeyParamNameValue
{
    [_triggers addMappings:triggerKeyParamNameValue];
    [_graph triggersChanged:self];
    [_audio triggersChanged:self];
}

-(void)removeTriggers:(NSDictionary *)triggerKeyParamNameValue
{
    [_triggers removeMappings:triggerKeyParamNameValue];
    [_graph triggersChanged:self];
    [_audio triggersChanged:self];
}


-(void)dealloc
{
    NSLog(@"Scene dealloc");
}

-(void)pause
{
    [_audio pause];
    [_graph pause];
}

-(void)play
{
    [_audio play];
    [_graph play];
}

- (void)getSettings:(NSMutableArray *)putHere
{
    [_graph getSettings:putHere];
    [_audio getSettings:putHere];
}

-(NSDictionary *)getRuntimeConnections
{
    return @{};
}

-(void)queue:(TriggerTween *)tweener
{
    if( [_tweenQueue indexOfObject:tweener] == NSNotFound )
        [_tweenQueue addObject:tweener];
}

-(void)update:(NSTimeInterval)dt view:(GraphView *)view
{
    if( !_started )
    {
        _started = true;
        [_audio start];
        return; // see you in 1/60th of a second!
    }
    
    [_audio update:dt];
    [view update:dt];
    
    if( [_tweenQueue count] )
    {
        NSIndexSet * markedForDelete = [_tweenQueue indexesOfObjectsPassingTest:^BOOL(TriggerTween * tween, NSUInteger idx, BOOL *stop) {
            return [tween update:dt];
        }];
        [_tweenQueue removeObjectsAtIndexes:markedForDelete];
    }
}

@end
