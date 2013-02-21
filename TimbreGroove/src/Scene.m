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
#import "Global.h"
#import "Audio.h"

@interface Scene () {
    TriggerMap * _map;
    NSMutableDictionary * _dynamicProps;
    ConfigScene * _config;
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
        _dynamicProps = [NSMutableDictionary new];
        _map = [[TriggerMap alloc] initWithWatchee:self];
        _config = config;
        _graph = [Graph new];
        Global * g = [Global sharedInstance];
        [_graph createTopLevelNodeWithConfig:config.graphicElement andViewSize:g.graphViewSize];
        _audio = [Audio new];
        [_audio loadAudioFromConfig:config.audioElement];
        [_map addParameters:[_graph getParameters]];
        [_map addParameters:[_audio getParameters]];
        [_map addMappings:config.connections];
        [_map addMappings:[self getRuntimeConnections]];
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

-(NSDictionary *)getRuntimeConnections
{
    return @{};
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
