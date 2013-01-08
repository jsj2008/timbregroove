//
//  TGGraph.m
//  TimbreGroove
//
//  Created by victor on 12/15/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGElementGraph.h"

@implementation TGElementGraph

+(void)_inner_update:(NSArray *)children dt:(NSTimeInterval)dt
{
    for( TG3dObject * child in children )
    {
        [child update:dt];
        [self _inner_update:child.children dt:dt];
    }
}

-(void)update:(NSTimeInterval)dt
{
    // update Camera and ModelView (position,rotation) here
    [TGElementGraph _inner_update:self.children dt:dt];
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
    // update Camera and ModelView (position,rotation) here
    [TGElementGraph _inner_render:self.children w:w h:h];
}

@end
