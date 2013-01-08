//
//  TGPlane.m
//  
//
//  Created by victor on 12/15/12.
//
//

#import "TGPlane.h"

static TGGenericElementParams gep;

#define NUM_POINTS 6

static float v[NUM_POINTS*(3+2)] = {
    //   x   y  z    u    v
    -1, -1, 0,   0,   0,
    -1,  1, 0,   0,   1,
    1, -1, 0,   1,   0,
    
    -1,  1, 0,   0,   1,
    1,  1, 0,   1,   1,
    1, -1, 0,   1,   0
};

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

@implementation TGPlane


-(TGPlane *)initWithColor:(GLKVector4)color
{
    if( (self = [super initWithParams:initColor(color)]) )
    {
    }
    return self;
}

-(TGPlane *)initWithFileName:(NSString *)fileName
{
    if( (self = [self init]) )
    {
    }
    return self;
}

@end
