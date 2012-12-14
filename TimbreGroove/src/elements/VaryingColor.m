//
//  AOTK.m
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "VaryingColor.h"
#import "TGShader.h" 
#import "TGVertexBuffer.h"  
#import "TGVariables.h"
#import "TGViewController.h"

@implementation VaryingColor

-(VaryingColor *)init
{
    if( (self = [super init]) )
    {
#define NUM_POINTS 6
        
        float v[NUM_POINTS*(3+4)] = {
        //   x   y  z    r    g   b,  a,
            -1, -1, 0,   0,   0,  1,  1,
            -1,  1, 0,   0,   1,  0,  1,
             1, -1, 0,   1,   0,  0,  1,
            
            -1,  1, 0,   1,   1,  0,  1,
             1,  1, 0,   1,   0,  1,  1,
             1, -1, 0,   1,   1,  1,  1
        };

        TGShader * shader = [[TGShader alloc] initWithName:@"color"];
        
        self.shader = shader;
        
        TGVertexBuffer * buffer = [[TGVertexBuffer alloc] init];
        
        TGVertexStride s[2];
        StrideInit3fv(s,   "a_position");
        StrideInit4fv(s+1, "a_color");
        
        [buffer setData:v strides:s countStrides:2 numElem:NUM_POINTS shader:shader];
        
        [self addBuffer:buffer];

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
    
    GLfloat red[4] = { 1, 0, 0, 1 };
    [self.shader.uniforms write:@"u_color" type:TG_VECTOR4 data:red];
    
    [self.shader writePVM:@"u_mvpMatrix"];
}

@end
