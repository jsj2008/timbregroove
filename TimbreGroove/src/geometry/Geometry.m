//
//  Geometry.m
//  TimbreGroove
//
//  Created by victor on 1/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Geometry.h"
#import "GenericShader.h"

@implementation Geometry

-(void)createWithIndicesIntoNames:(NSArray *)indicesIntoNames
{
    _UVs = [indicesIntoNames containsObject:@(gv_uv)];
    _normals = [indicesIntoNames containsObject:@(gv_normal)];
    [self createBufferDataByStride:[self getStrideSizes] indicesIntoNames:indicesIntoNames];
}

-(NSArray *)getStrideSizes
{

    NSArray * ret = nil;
    
    if( _UVs )
    {
        if( _normals )
            ret = @[@(3),@(2),@(3)];
        else
            ret = @[@(3),@(2)];
    }
    else
    {
        if( _normals )
            ret = @[@(3),@(3)];
        else
            ret = @[@(3)];
    }
    
    return ret;
}

-(void)createBufferDataByStride:(NSArray *)strideSizes
             indicesIntoNames:(NSArray *)indicesIntoNames
{
    GeometryStats stats;
    [self getStats:&stats];
    
    VertexStride *   strides;
    unsigned int     numStrides;
    void *           vertexData;
    unsigned int     numVertices;
    unsigned int *   indexData = NULL;
    unsigned int     numIndices;
    
    numStrides = [strideSizes count];
    
    strides = malloc(sizeof(VertexStride)*numStrides);
    
    for( int i = 0; i < numStrides; i++ )
    {
        VertexStride * stride = strides + i;
        int size = [strideSizes[i] intValue];
        switch (size) {
            case 1:
                StrideInit1f(stride);
                break;
            case 2:
                StrideInit2f(stride);
                break;
            case 3:
                StrideInit3f(stride);
                break;
            case 4:
                StrideInit4f(stride);
                break;
#if DEBUG
            default:
                TGLog(LLShitsOnFire, @"Unknown stride size");
                exit(1);
                break;
#endif
        }
        stride->indexIntoShaderNames = [indicesIntoNames[i] intValue];
    }
    
    numVertices = stats.numVertices;
    numIndices  = stats.numIndices;
    GLsizei sz = [MeshBuffer calcDataSize:strides countStrides:numStrides numVertices:numVertices];
    vertexData = malloc(sz);
    if( numIndices > 0 )
        indexData = malloc( sizeof(unsigned int) * numIndices );
    
    [self getBufferData:vertexData
              indexData:indexData
                withUVs:_UVs
            withNormals:_normals];
    
    [self setData:vertexData
          strides:strides
     countStrides:numStrides
      numVertices:numVertices
        indexData:indexData
       numIndices:numIndices];
        
    free(strides);
    free(vertexData);
    if( indexData )
        free(indexData);
}

// for dynamic draw
-(void)resetVertices
{
    void * vertexData = malloc(self.bufferSize);
    [self getBufferData:vertexData indexData:NULL withUVs:_UVs withNormals:_normals];
    [self setData:vertexData];
    free(vertexData);
}

-(void)getStats:(GeometryStats *)stats
{
    
}
-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
             withUVs:(bool)withUVs
         withNormals:(bool)withNormals
{
    
}
@end
