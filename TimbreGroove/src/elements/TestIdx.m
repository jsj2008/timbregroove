//
//  AOTK.m
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TestIdx.h"


@implementation TestIdx

-(void)createBuffer
{
    [self createBufferDataByType:@[@(sv_pos),@(sv_acolor)] numVertices:4 numIndices:6];
}

-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
{
    static float v[4*(3+4)] = {
    //   x   y  z    r    g   b,  a,
      -1.6, -1, 0,   0,   0,  0,  1,
        -1,  1, 0,   1,   1,  1,  1,
         1, -1, 0,   0,   0,  0,  1,
         1,  1, 0,   1,   1,  1,  1  // ,
    };
    
    static unsigned int idx[6] = {
        
        0, 1, 2, 1, 3, 2
    };
   
    memcpy(vertextData,   v, sizeof(v));
    memcpy(indexData,   idx, sizeof(idx));
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
