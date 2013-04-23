//
//  Sky.m
//  TimbreGroove
//
//  Created by victor on 4/22/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Sky.h"
#import "GridPlane.h"

@interface SkyPlane : Painter
@end
@implementation SkyPlane

-(id)wireUp
{
    self.position = (GLKVector3){ 0, 0, -9 };
    self.scaleXYZ = 40;
    return [super wireUp];
}

-(void)createBuffer
{
    [super createBuffer];
    
    MeshBuffer * mb = [GridPlane gridWithIndicesIntoNames:@[@(gv_pos),@(gv_normal)]
                                                 andDoUVs:false
                                              andDoNormals:true];
    [self addBuffer:mb];
    
    static GLKVector4 colors[] = {
        { 0.0, 0.0, 0.5, 1 },
        { 0.4, 0.4, 0.7, 1 },
        { 0.0, 0.0, 0.5, 1 },
        { 0.4, 0.4, 0.7, 1 }
    };
    
    ColorBuffer * cb = [[ColorBuffer alloc] init];
    [cb setDataWithRGBAs:(float *)&colors numColors:4 indexIntoNames:gv_acolor];
    [self addBuffer:cb];
}
@end

@implementation Sky

-(id)wireUp
{
    [self appendChild:[[[SkyPlane alloc] init] wireUp]];
    return [super wireUp];
}

@end