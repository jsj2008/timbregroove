//
//  SimpleImage.m
//  TimbreGroove
//
//  Created by victor on 12/20/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "SimpleImage.h"
#import "MeshBuffer.h"

static MeshBuffer * __sharedBuffer;

@implementation SimpleImage

-(id)initWithTextureFile:(const char *)fileName
{
    return [super initWithTextureFile:fileName];
}

-(void)createBuffer
{
    if( __sharedBuffer == nil )
    {
        [self createBufferDataByType:@[@(sv_pos),@(sv_uv)] numVertices:6 numIndices:0];
        __sharedBuffer = _buffers[0];
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
    static float v[6*(3+2)] = {
    //   x   y  z    u    v
        -1, -1, 0,   0,   0,
        -1,  1, 0,   0,   1,
         1, -1, 0,   1,   0,
        
        -1,  1, 0,   0,   1,
         1,  1, 0,   1,   1,
         1, -1, 0,   1,   0
    };
    
    memcpy(vertextData, v, sizeof(v));
}


@end
