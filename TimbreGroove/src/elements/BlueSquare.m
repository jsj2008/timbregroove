//
//  BlueSquare.m
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "BlueSquare.h"

#import "TGVertexBuffer.h"
#import "TGCamera.h"
#import "TGViewController.h"
#import "TGShader.h"

@implementation BlueSquare

-(BlueSquare *)init
{
    if( (self = [super init]) )
    {
#define NUM_POINTS 6
        
        float v[NUM_POINTS*3] = {
        //   x   y  z 
            -1, -1, 0,
            -1,  1, 0,
             1, -1, 0,
            
            -1,  1, 0,
             1,  1, 0,
             1, -1, 0
        };
        
        GLKVector4 blue = { 0.0f, 0.0f, 1.0f, 1.0f };
        
        self.shader = [TGShader shader:@"vanilla"];
        TGVertexBuffer * buffer = [[TGVertexBuffer alloc] init];
        
        TGVertexStride s;
        StrideInit3fv(&s, "a_position");
        [buffer setData:v strides:&s countStrides:1 numElem:NUM_POINTS shader:self.shader];
        
        [self.shader.uniforms write:@"u_color" type:TG_VECTOR4 data:blue.v];
    }
    
    return self;
}

-(void)update:(TGViewController *)vc
{
    static NSTimeInterval dt;
    
    dt += (vc.timeSinceLastUpdate * 50.0f);
    
    GLfloat r = GLKMathDegreesToRadians(dt);

    GLKVector3 rot = { 0, r, 0 };    
    self.rotation = rot;
}
@end
