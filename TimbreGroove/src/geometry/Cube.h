//
//  Cube.h
//  TimbreGroove
//
//  Created by victor on 1/21/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Geometry.h"

typedef enum CubeTextureWrap
{
    kCubeWrapRepeat,
    kCubeWrapHorizontal,
    kCubeWrapVertical
} CubeTextureWrap;

@interface Cube : Geometry

+(id) cubeWithIndicesIntoNames:(NSArray *)indicesIntoNames;


+(id) cubeWithWidth:(float)width
andIndicesIntoNames:(NSArray *)indicesIntoNames;

+(id) cubeWithIndicesIntoNames:(NSArray *)indicesIntoNames
                      wrapType:(CubeTextureWrap)wrapType;


+(id) cubeWithWidth:(float)width
andIndicesIntoNames:(NSArray *)indicesIntoNames
           wrapType:(CubeTextureWrap)wrapType;

@end
