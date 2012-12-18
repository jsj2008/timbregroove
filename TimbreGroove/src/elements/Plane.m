//
//  TGPlane.m
//  
//
//  Created by victor on 12/15/12.
//
//

#import "Plane.h"

static TGGenericElementParams gep;

#define NUM_POINTS 6

static TGGenericElementParams * initTexture(const char *textureFileName)
{
    static float v[NUM_POINTS*(3+2)] = {
        //   x   y  z    u    v
        -1, -1, 0,   0,   0,
        -1,  1, 0,   0,   1,
        1, -1, 0,   1,   0,
        
        -1,  1, 0,   0,   1,
        1,  1, 0,   1,   1,
        1, -1, 0,   1,   0
    };
    
    static TGVertexStride stride[2];
    StrideInit3f(stride,   sv_pos);
    StrideInit2f(stride+1, sv_uv);
    
    GLKVector4 none = { -1.0, -1.0,-1.0,-1.0 };
    gep.bufferData = v;
    gep.color = none;
    gep.numElements = NUM_POINTS;
    gep.numStrides = sizeof(stride)/sizeof(stride[0]);
    gep.opacity = 0.6;
    gep.strides = stride;
    gep.texture = textureFileName;
    
    return &gep;
}


static TGGenericElementParams * initColor(GLKVector4 color)
{
    static float v[NUM_POINTS*3] = {
        //   x   y  z
        -1, -1, 0,
        -1,  1, 0,
        1, -1, 0,
        
        -1,  1, 0,
        1,  1, 0,
        1, -1, 0
    };

    static TGVertexStride stride[1];
    StrideInit3f(stride,   sv_pos);
    
    gep.bufferData = v;
    gep.color = color;
    gep.numElements = NUM_POINTS;
    gep.numStrides = sizeof(stride)/sizeof(stride[0]);
    gep.opacity = 1.0;
    gep.strides = stride;
    gep.texture = NULL;
    
    return &gep;
}

@implementation Plane


-(Plane *)initWithColor:(GLKVector4)color
{
    if( (self = [super initWithParams:initColor(color)]) )
    {
    }
    return self;
}

-(Plane *)initWithFileName:(const char *)fileName
{
    if( (self = [self initWithParams:initTexture(fileName)]) )
    {
    }
    return self;
}

@end
