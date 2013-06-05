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
@property (nonatomic) bool verticies;
@property (nonatomic) bool acolors;

// for shaders with standard attributes: position, texture, normals
-(void)createWithIndicesIntoNames:(NSArray *)indicesIntoNames;

// for shaders with non-standard attributes:

-(void)createBufferDataByStride:(NSArray *)strideSizes
             indicesIntoNames:(NSArray *)indicesIntoNames;

// for derived classes
-(void)getStats:(GeometryStats *)stats;
-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData;

// for derived classes that use dynamic draw
-(void)resetVertices;

@end
