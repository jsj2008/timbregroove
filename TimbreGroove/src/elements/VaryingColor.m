//
//  AOTK.m
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "VaryingColor.h"
#import "TGViewController.h"

static TGGenericElementParams * initParams()
{
#define NUM_POINTS 6

    static float v[NUM_POINTS*(3+4)] = {
    //   x   y  z    r    g   b,  a,
        -1, -1, 0,   0,   0,  1,  1,
        -1,  1, 0,   0,   1,  0,  1,
         1, -1, 0,   1,   0,  0,  1,
        
        -1,  1, 0,   1,   1,  0,  1,
         1,  1, 0,   1,   0,  1,  1,
         1, -1, 0,   1,   1,  1,  1
    };
    
    static TGVertexStride stride[2];
    StrideInit3f(stride,   sv_pos);
    StrideInit4f(stride+1, sv_acolor);

    static GLKVector4 none = { -1.0f, -1.0f,-1.0f,-1.0f, };
    
    
    static TGGenericElementParams p;
    p.bufferData = v;
    p.color = none;
    p.numElements = NUM_POINTS;
    p.numStrides = sizeof(stride)/sizeof(stride[0]);
    p.opacity = 1.0;
    p.strides = stride;
    p.texture = NULL;
    
    return &p;
}

@implementation VaryingColor

-(VaryingColor *)init
{
    if( (self = [super initWithParams:initParams()]) )
    {


    }
    
    return self;
}

-(void)update:(NSTimeInterval)dt
{
    static NSTimeInterval __dt;
    
    __dt += (dt * 50.0f);
    
    GLfloat r = GLKMathDegreesToRadians(__dt);
    
    GLKVector3 rot = { r, 0, 0 };
    self.rotation = rot;
}

@end
