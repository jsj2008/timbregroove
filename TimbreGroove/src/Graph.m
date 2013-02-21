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

@interface Graph() {
    // as of this writing the majority of graphs (all?)
    // only have one top level node. Keep a pointer
    // so we don't do any unnecessary ARC calls into _kids[]
    // during update and render
     __weak  TG3dObject * _single;
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

-(id)createTopLevelNodeWithConfig:(ConfigGraphicElement *)config andViewSize:(CGSize)viewSize;
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

-(void)play               { [self traverse:_cmd userObj:self.view]; }
-(void)pause              { [self traverse:_cmd userObj:self.view]; }
-(void)stop               { [self traverse:_cmd userObj:self.view]; }

+(void)_inner_update:(NSArray *)children dt:(NSTimeInterval)dt  mixerUpdate:(MixerUpdate *)mixerUpdate
{
    for( TG3dObject * child in children )
    {
        child->_totalTime += dt;
        child->_timer += dt;
        [child update:dt mixerUpdate:mixerUpdate];
        NSArray * c = child.children;
        if( c )
            [self _inner_update:c dt:dt mixerUpdate:mixerUpdate];
    }
}

-(void)update:(NSTimeInterval)dt mixerUpdate:(MixerUpdate *)mixerUpdate
{
    if( _single )
    {
        _single->_totalTime += dt;
        _single->_timer += dt;
        [_single update:dt mixerUpdate:mixerUpdate];
    }
    else
        [Graph _inner_update:self.children dt:dt mixerUpdate:mixerUpdate];
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

-(NSArray *)getSettings
{
    NSMutableArray * settings = [NSMutableArray new];
    for( TG3dObject * child in self.children )
    {
        NSArray * arr = [child getSettings];
        if( arr && [arr count] )
           [settings addObjectsFromArray:arr];
    }
    
    return settings;
}

-(id)settingsChanged
{
    for( TG3dObject * child in self.children )
    {
        [child settingsChanged];
    }
    
    return nil;
}

-(NSDictionary *)getParameters
{
    NSMutableDictionary * params = [NSMutableDictionary new];
    for( TG3dObject * child in self.children )
    {
        NSDictionary * dict = [child getParameters];
        if( dict && [dict count] )
           [params addEntriesFromDictionary:dict];
    }
    
    return params;
}

@end
