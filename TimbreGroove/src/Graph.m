//
//  TGGraph.m
//  TimbreGroove
//
//  Created by victor on 12/15/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Graph.h"
#import "Camera.h"

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

-(void)play               { [self traverse:_cmd userObj:self.view]; }
-(void)pause              { [self traverse:_cmd userObj:self.view]; }
-(void)stop               { [self traverse:_cmd userObj:self.view]; }

+(void)_inner_update:(NSArray *)children dt:(NSTimeInterval)dt
{
    for( TG3dObject * child in children )
    {
        child.totalTime += dt;
        child.timer += dt;
        [child update:dt];
        NSArray * c = child.children;
        if( c )
            [self _inner_update:c dt:dt];
    }
}

-(void)update:(NSTimeInterval)dt
{
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
    [Graph _inner_render:self.children w:w h:h];
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

-(id)rewire
{
    for( TG3dObject * child in self.children )
    {
        [child rewire];
    }
    
    return nil;
}
@end
