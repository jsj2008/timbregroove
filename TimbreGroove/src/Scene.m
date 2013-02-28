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
#import "NSValue+Parameter.h"

@interface Scene () {
    TriggerMap * _map;
    NSMutableDictionary * _dynamicProps;
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
        _dynamicProps = [NSMutableDictionary new];
        _map = [[TriggerMap alloc] initWithWatchee:self];
        _config = config;
        _audio = [Audio audioFromConfig:config.audioElement];
        _graph = [Graph new];
        Global * g = [Global sharedInstance];
        [_graph createTopLevelNodeWithConfig:config.graphicElement andViewSize:g.graphViewSize];
        [_map addParameters:[_graph getParameters]];
        [_map addParameters:[_audio getParameters]];
        NSArray * connectionMaps = config.connections;
        for( NSDictionary * map in connectionMaps )
            [_map addMappings:map];
        [_map addMappings:[self getRuntimeConnections]];
    }
    return self;
}

-(void)dealloc
{
    [_map detach:self];
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

-(void)setParameter:(NSString const *)name
              value:(float)value
               func:(TweenFunction)f
           duration:(NSTimeInterval)duration
{
    ParamPayload pv;
    pv.v.f = value;
    pv.type = TG_FLOAT;
    pv.additive = false;
    pv.duration = duration;
    pv.function = f;
    [self setValue:[NSValue valueWithPayload:pv] forKey:(NSString *)name];    
}

-(void)tweakParameter:(NSString const *)name
                value:(float)value
                 func:(TweenFunction)func
             duration:(NSTimeInterval)duration
{
    ParamPayload pv;
    pv.v.f = value;
    pv.type = TG_FLOAT;
    pv.additive = true;
    pv.duration = duration;
    pv.function = func;
    [self setValue:[NSValue valueWithPayload:pv] forKey:(NSString *)name];
}

-(void)tweakTrigger:(NSString const *)name by:(float)value
{
    ParamPayload pv;
    pv.v.f = value;
    pv.type = TG_FLOAT;
    pv.additive = true;
    pv.duration = 0;
    [_map trigger:name withValue:[NSValue valueWithPayload:pv]];
    
}

-(void)tweakTrigger:(NSString const *)name byPoint:(CGPoint)pt
{
    ParamPayload pv;
    PvToPoint(pv.v) = pt;
    pv.type = TG_VECTOR2;
    pv.additive = true;
    pv.duration = 0;
    [_map trigger:name withValue:[NSValue valueWithPayload:pv]];
}

-(void)setTrigger:(NSString const *)name value:(float)value
{
    ParamPayload pv;
    pv.v.f = value;
    pv.type = TG_FLOAT;
    pv.additive = false;
    pv.duration = 0;
    [_map trigger:name withValue:[NSValue valueWithPayload:pv]];
}

-(void)setTrigger:(NSString const *)name b:(bool)b
{
    ParamPayload pv;
    pv.v.boool = b;
    pv.type = TG_BOOL;
    pv.additive = false;
    pv.duration = 0;
    [_map trigger:name withValue:[NSValue valueWithPayload:pv]];
}

-(void)setTrigger:(NSString const *)name point:(CGPoint)pt
{
    ParamPayload pv;
    PvToPoint(pv.v) = pt;
    pv.type = TG_VECTOR2;
    pv.additive = false;
    pv.duration = 0;
    [_map trigger:name withValue:[NSValue valueWithPayload:pv]];
}

-(void)setTrigger:(NSString const *)name withValue:(NSValue *)value
{
    [_map trigger:name withValue:value];
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
    if( !_started )
    {
        _started = true;
        [_audio start];
        return; // see you in 1/60th of a second!
    }
    
    [_audio update:dt scene:self];
    [view update:dt];
    
    for( Parameter * param in _tweenQueue )
    {
        [param update:dt];
        if( param.isCompleted )
            [_tweenQueue removeObject:param];
    }
}

-(void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    ParamPayload pl = [(NSValue *)value ParamPayloadValue];
    _dynamicProps[key] = [NSValue valueWithPayload:pl];
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
