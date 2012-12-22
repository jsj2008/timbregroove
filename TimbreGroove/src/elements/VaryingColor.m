//
//  AOTK.m
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "VaryingColor.h"
#import "TGViewController.h"


@implementation VaryingColor

-(void)createBuffer
{
    [self createBufferDataByType:@[@(sv_pos),@(sv_acolor)] numVertices:6 numIndices:0];
}

-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
{
    static float v[6*(3+4)] = {
   //   x   y  z    r    g   b,  a,
        -1, -1, 0,   0,   0,  1,  1,
        -1,  1, 0,   0,   1,  0,  1,
         1, -1, 0,   1,   0,  0,  1,
        
        -1,  1, 0,   1,   1,  0,  1,
         1,  1, 0,   1,   0,  1,  1,
         1, -1, 0,   1,   1,  1,  1
    };
    
    memcpy(vertextData, v, sizeof(v));
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
