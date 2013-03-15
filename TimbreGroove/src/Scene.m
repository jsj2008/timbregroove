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
    NSMutableArray * _tweenQueue;
    bool _paused;
    bool _useProxy;
    Audio * _proxyAudio;
    NSArray * _configConnections;
}

@end
@implementation Scene

+(id)defaultScene
{
    ConfigScene * config = [Config defaultScene];
    return [[Scene alloc] initWithConfig:config];
}

+(id)sceneWithName:(NSString *)name
{
    ConfigScene * config = [[Config sharedInstance] getScene:name];
    return [[Scene alloc] initWithConfig:config];
}

+(id)systemSceneWithName:(NSString *)name
{
    ConfigScene * config = [[Config sharedInstance] getSystemScene:name];
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
        [self doInitWithConfig:config];
    }
    return self;
}

-(void)doInitWithConfig:(ConfigScene *)config
{
    _audio = [Audio audioFromConfig:config.audioElement withScene:self];
    
    _graph = [Graph new];
    Global * g = [Global sharedInstance];
    [_graph loadFromConfig:config.graphicElement andViewSize:g.graphViewSize modal:false];
    _configConnections = config.connections;
    [self wireUp:false];
}

-(void)wireUp:(bool)getTriggers
{
    bool wasPaused = _paused;
    _paused = true;
    
    _tweenQueue = [NSMutableArray new];
    _triggers = [[TriggerMap alloc] initWithDelegate:self];
    
    NSMutableDictionary * params = [NSMutableDictionary new];
    [_graph getParameters:params];
    [_audio getParameters:params];
    [_triggers addParameters:params];
    
    [_configConnections apply:^(id map)
     {
         [_triggers addMappings:map];
     }];
    
    NSMutableArray * maps = [NSMutableArray new];
    [_graph getTriggerMap:maps];
    [_audio getTriggerMap:maps];
    if( [maps count] )
    {
        [maps apply:^(id map) {
            [_triggers addMappings:map];
        }];
    }
    
    if( getTriggers )
    {
        [_graph triggersChanged:self];
        [_audio triggersChanged:self];
    }
    _paused = wasPaused;
}

-(void)decomission
{
    _triggers = nil;
    _tweenQueue = nil;
    [_graph triggersChanged:nil];
    [_audio triggersChanged:nil];
}

-(void)dealloc
{
    NSLog(@"Scene dealloc");
}

-(void)pause
{
    _paused = true;
    [_audio pause];
    [_graph pause];
    [_graph triggersChanged:nil];
    [_audio triggersChanged:nil];
}

-(void)activate
{
    [_graph triggersChanged:self];
    [_audio triggersChanged:self];
    [_audio activate];
    [_graph activate];
    _paused = false;
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
    if( _paused )
        return;
    
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
