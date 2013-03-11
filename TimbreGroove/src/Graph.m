//
//  TGGraph.m
//  TimbreGroove
//
//  Created by victor on 12/15/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Graph.h"
#import "Camera.h"
#import "Global.h"
#import "Config.h"
#import "GraphView+Touches.h"

#import "Parameter.h"
#import "TriggerMap.h"
#import "Scene.h"
#import "Names.h"

@interface Graph() {
    // as of this writing the majority of graphs (all?)
    // only have one top level node. Keep a pointer
    // so we don't do any unnecessary ARC calls into _kids[]
    // during update and render
     __weak  TG3dObject * _single;
    
    NSTimeInterval _runningTime;
    bool _isPaused;
    FloatParamBlock _timerTrigger;
    FloatParamBlock _updateTrigger;
}

@end
@implementation Graph

-(id)init
{
    self = [super init];
    if( self )
    {
        self.camera = [Camera new];        
    }
    
    return self;
}

-(void)dealloc
{
    NSLog(@"Graph object gone");
}

-(id)loadFromConfig:(ConfigGraphicElement *)config andViewSize:(CGSize)viewSize;
{
    Class klass = NSClassFromString(config.instanceClass);
    TG3dObject * node = [[klass alloc] init];
    [self appendChild:node];
    NSDictionary * userData = config.customProperties;
    if( userData )
        [node setValuesForKeysWithDictionary:userData];
    [node wireUpWithViewSize:viewSize];
    return node;
}

-(void)appendChild:(Node *)child
{    
    _single = _kids == nil ? (TG3dObject*)child : nil;
    [super appendChild:child];
}

-(void)play
{
    _isPaused = false;
//    [self traverse:_cmd userObj:self.view];
}

-(void)pause
{
    _isPaused = true;
//    [self traverse:_cmd userObj:self.view];
}

+(void)_inner_update:(NSArray *)children dt:(NSTimeInterval)dt
{
    for( TG3dObject * child in children )
    {
        child->_totalTime += dt;
        child->_timer += dt;
        [child update:dt];
        NSArray * c = child.children;
        if( c )
            [self _inner_update:c dt:dt];
    }
}

-(void)update:(NSTimeInterval)dt
{
    if( _isPaused )
        return;
    
    if( _timerTrigger )
    {
        _runningTime += dt;
        _timerTrigger(_runningTime);
    }
    
    if( _updateTrigger )
        _updateTrigger(dt);
    
    if( _single )
    {
        _single->_totalTime += dt;
        _single->_timer += dt;
        [_single update:dt];
    }
    else
        [Graph _inner_update:self.children dt:dt];
}

+(void)_inner_render:(NSArray *)children w:(NSUInteger)w h:(NSUInteger)h
{
    for( TG3dObject * child in children )
    {
        [child render:w h:h];
        NSArray * c = child.children;
        if( c )
            [self _inner_render:c w:w h:h];
    }
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    if( _isPaused )
        return;
    
    if( _single )
    {
        [_single render:w h:h];
        if( _single.autoRenderChildren && _single.children )
            [Graph _inner_render:_single.children w:w h:h];
    }
    else
    {
        [Graph _inner_render:self.children w:w h:h];
    }
}

- (void)getSettings:(NSMutableArray *)settings
{
    if( _single )
        [_single getSettings:settings];
    else
        [self.children apply:^(TG3dObject * child) { [child getSettings:settings]; }];
}

-(id)settingsChanged
{
    if( _single )
        [_single settingsChanged];
    else
        [self.children apply:^(TG3dObject * child) { [child settingsChanged]; }];
    return nil;
}

-(void)getParameters:(NSMutableDictionary *)putHere;
{
    if( _single )
        [_single getParameters:putHere];
    else
        [self.children apply:^(TG3dObject * child) { [child getParameters:putHere]; }];
}

-(void)triggersChanged:(Scene *)scene
{
    if( scene )
    {
        _timerTrigger  = [scene.triggers getFloatTrigger:kTriggerTimer];
        _updateTrigger = [scene.triggers getFloatTrigger:kTriggerUpdate];
    }
    else
    {
        _timerTrigger = nil;
        _updateTrigger = nil;
    }
    
    if( _single )
        [_single triggersChanged:scene];
    else
        [self.children apply:^(TG3dObject * child) { [child triggersChanged:scene]; }];
}

-(void)didAttachToView:(GraphView *)view
{
    [view triggersChanged:[Global sharedInstance].scene];
}
@end
