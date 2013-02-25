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
    TriggerMap * _map;
    NSMutableDictionary * _dynamicProps;
    ConfigScene * _config;
    NSMutableArray * _tweenQueue;
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
        _dynamicProps = [NSMutableDictionary new];
        _map = [[TriggerMap alloc] initWithWatchee:self];
        _config = config;
        _graph = [Graph new];
        Global * g = [Global sharedInstance];
        _audio = [Audio new];
        [_audio loadAudioFromConfig:config.audioElement];
        [_graph createTopLevelNodeWithConfig:config.graphicElement andViewSize:g.graphViewSize];
        [_map addParameters:[_graph getParameters]];
        [_map addParameters:[_audio getParameters]];
        NSArray * connectionMaps = config.connections;
        for( NSDictionary * map in connectionMaps )
            [_map addMappings:map];
        [_map addMappings:[self getRuntimeConnections]];
        [_audio start];
    }
    return self;
}

-(void)dealloc
{
    [_graph cleanChildren];
}

-(void)setTrigger:(NSString const *)name value:(float)value
{
    [_map trigger:name withValue:[NSNumber numberWithFloat:value]];
}
-(void)setTrigger:(NSString const *)name b:(bool)b
{
    [_map trigger:name withValue:[NSNumber numberWithBool:b]];
}

-(void)setTrigger:(NSString const *)name point:(CGPoint)pt
{
    [_map trigger:name withValue:[NSValue valueWithCGPoint:pt]];
}
-(void)setTrigger:(NSString const *)name obj:(id)obj
{
    [_map trigger:name withValue:obj];
}

-(bool)somebodyExpectsTrigger:(NSString const *)triggerName
{
    return [_map expectsTrigger:triggerName];
}

-(NSDictionary *)getRuntimeConnections
{
    return @{};
}

-(void)queue:(Parameter *)parameter
{
    [_tweenQueue addObject:parameter];
}

-(void)update:(NSTimeInterval)dt view:(GraphView *)view
{
    MixerUpdate mixerUpdate;
    [_audio update:dt mixerUpdate:&mixerUpdate];
    [view update:dt mixerUpdate:&mixerUpdate];
    for( Parameter * param in _tweenQueue )
    {
        [param update:dt];
        if( param.isCompleted )
           [_tweenQueue removeObject:param];        
    }
}

-(void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    _dynamicProps[key] = value;
}

-(id)valueForUndefinedKey:(NSString *)key
{
    for( NSString * dkey in _dynamicProps )
    {
        if( [dkey isEqualToString:key] )
            return _dynamicProps[dkey];
    }
    return nil;
}

@end
