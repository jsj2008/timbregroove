//
//  TGPlane.m
//  
//
//  Created by victor on 12/15/12.
//
//

#import "Plane.h"
#import "MeshBuffer.h"

static MeshBuffer * __sharedBuffer;

@implementation Plane


-(void)createBuffer
{
    if( __sharedBuffer == nil )
    {
        __sharedBuffer = [self createBufferDataByType:@[@(sv_pos)] numVertices:6 numIndices:0];
    }
    else
    {
        if( !_buffers )
            _buffers = [NSMutableArray new];
        [_buffers addObject:__sharedBuffer];
        NSLog(@"reusing vertext buffer %d",__sharedBuffer.glVBuffer);
    }
}

-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
{
    static float v[6*3] = {
        //   x   y  z
        -1, -1, 0,
        -1,  1, 0,
        1, -1, 0,
        
        -1,  1, 0,
        1,  1, 0,
        1, -1, 0
    };
    
    memcpy(vertextData, v, sizeof(v));
}

@end
