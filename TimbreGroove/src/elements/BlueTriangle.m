//
//  BlueSquare.m
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "BlueTriangle.h"

#import "TGVertexBuffer.h"
#import "TGCamera.h"
#import "TGViewController.h"
#import "TGShader.h"


static TGGenericElementParams * initParams()
{
#define NUM_POINTS 3
    
    static float v[NUM_POINTS*3] = {
        -1, -1, 0,
        0,   1, 0,
        1,  -1, 0
    };
    
    static GLKVector4 blue = { 0.0f, 0.0f, 1.0f, 1.0f };

    static TGVertexStride stride;
    StrideInit3f(&stride, sv_pos);
    
    static TGGenericElementParams p;
    p.vertexData = v;
    p.color = blue;
    p.numVertices = NUM_POINTS;
    p.numStrides = 1;
    p.opacity = 1.0;
    p.strides = &stride;
    p.texture = NULL;
    
    return &p;
}

@implementation BlueTriangle

-(BlueTriangle *)init
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

    GLKVector3 rot = { 0, r, 0 };    
    self.rotation = rot;
}
@end
