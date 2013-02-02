//
//  TGGraph.m
//  TimbreGroove
//
//  Created by victor on 12/15/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Graph.h"

@interface Graph () {
    TG3dObject * _single;
}

@end
@implementation Graph

-(void)play               { [self traverse:_cmd userObj:self.view]; }
-(void)pause              { [self traverse:_cmd userObj:self.view]; }
-(void)stop               { [self traverse:_cmd userObj:self.view]; }

-(void)appendChild:(Node *)child
{
    if( _kids )
        _single = nil;
    else
        _single = (TG3dObject *)child;

    [super appendChild:child];
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
    if( _single )
    {
        _single->_totalTime += dt;
        _single->_timer += dt;
        [_single update:dt];
    }
    else
    {
        [Graph _inner_update:self.children dt:dt];
    }
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
    }
    else
    {
        [Graph _inner_render:self.children w:w h:h];
    }
}


@end
