//
//  AOTK.m
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "VaryingColor.h"
#import "GenericShader.h"
#import "GridPlane.h"
#import "MeshBuffer.h"

@interface VaryingColor () {
    ColorBuffer * _colorBuffer;
}

@end
@implementation VaryingColor

-(void)createBuffer
{
    GridPlane * gp = [GridPlane gridWithWidth:2.0
                                     andGrids:1
                          andIndicesIntoNames:@[@(gv_pos)]
                                     andDoUVs:false
                                 andDoNormals:false];
    [self addBuffer:gp];
    [self addColorBuffer];
}

-(void)addColorBuffer
{
    float cr = R0_1();
    float cg = R0_1();
    float cb = R0_1();
    float dr = R0_1();
    float dg = R0_1();
    float db = R0_1();
    
     float v[6*(3+4)] = {
   //   r         g        b,     a,
       R0_1(),   R0_1(),  R0_1(),  1,
       cr,       cg,      cb,      1,
       dr,       dg,      db,      1,
        
       cr,       cg,      cb,      1,
       R0_1(),   R0_1(),  R0_1(),  1,
       dr,       dg,      db,      1
    };
    
    if( _colorBuffer )
    {
        [_colorBuffer setData:v];
    }
    else
    {
        _colorBuffer = [[ColorBuffer alloc] init];
        _colorBuffer.usage = GL_DYNAMIC_DRAW;
        [_colorBuffer setDataWithRGBAs:v numColors:6 indexIntoNames:gv_acolor];
        [self addBuffer:_colorBuffer];
    }
}

-(void)update:(NSTimeInterval)dt
{
    static NSTimeInterval __second;
    
    __second += dt;
    
    if( __second > 1.0 )
    {
        [self addColorBuffer];
        __second = 0;
    }
        
    NSTimeInterval time = (self.totalTime * 50.0f);
    
    GLfloat r = GLKMathDegreesToRadians(time);
    
    GLKVector3 rot = { r, 0, 0 };
    self.rotation = rot;
}

@end
