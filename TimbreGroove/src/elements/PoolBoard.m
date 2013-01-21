//
//  PoolBoard.m
//  TimbreGroove
//
//  Created by victor on 1/21/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "PoolBoard.h"
#import "Pool.h"
#import "Texture.h"
#import "Cube.h"


@implementation PoolBoard

-(void)createBuffer
{
    MeshBuffer * buffer = [Cube cubeWithIndicesIntoNames:@[@(pool_position),@(pool_normal)]
                                                     andDoUVs:false
                                                 andDoNormals:true];
    
    [self addBuffer:buffer];
}

-(void)createShader
{
    self.shader = [Pool new];
}

-(void)createTexture
{
    self.texture = [[Texture alloc] initWithFileName:@"pool.png"];
}

-(void)getTextureLocations
{
    self.texture.uLocation = [self.shader location:pool_sampler];
}
@end
