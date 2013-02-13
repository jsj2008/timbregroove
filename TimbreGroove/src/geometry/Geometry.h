//
//  Geometry.h
//  TimbreGroove
//
//  Created by victor on 1/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MeshBuffer.h"
typedef struct GeomtryStats
{
    unsigned int numVertices;
    unsigned int numIndices;
} GeometryStats;

@interface Geometry : MeshBuffer

@property (nonatomic) bool UVs;
@property (nonatomic) bool normals;

// for shaders with standard attributes: position, texture, normals
-(void)createWithIndicesIntoNames:(NSArray *)indicesIntoNames
                            doUVs:(bool)UVs
                        doNormals:(bool)normals;

// for shaders with non-standard attributes:
-(void)createBufferDataByType:(NSArray *)strideTypes
             indicesIntoNames:(NSArray *)indicesIntoNames;

// for derived classes
-(void)getStats:(GeometryStats *)stats;
-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
             withUVs:(bool)withUVs
         withNormals:(bool)withNormals;

// for derived classes that use dynamic draw
-(void)resetVertices;

@end
