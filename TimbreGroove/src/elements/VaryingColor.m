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

@interface VaryingColor () {
    MeshBuffer * _colorBuffer;
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
    bool doAdd = false;
    
    if( !_colorBuffer )
    {
        _colorBuffer = [MeshBuffer new];
        _colorBuffer.usage = GL_DYNAMIC_DRAW;
        doAdd = true;
    }
    
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
    
    if( doAdd )
    {
        TGVertexStride stride;
        StrideInit4f(&stride);
        stride.indexIntoShaderNames = gv_acolor;
        
        [_colorBuffer setData:v strides:&stride countStrides:1 numVertices:6];
        
        [self addBuffer:_colorBuffer];
    }
    else
    {
        [_colorBuffer setData:v];
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
