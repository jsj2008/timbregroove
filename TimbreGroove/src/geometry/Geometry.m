//
//  Geometry.m
//  TimbreGroove
//
//  Created by victor on 1/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Geometry.h"

@implementation Geometry

-(void)createWithIndicesIntoNames:(NSArray *)indicesIntoNames
                            doUVs:(bool)UVs
                        doNormals:(bool)normals
{
    _UVs = UVs;
    _normals = normals;
    [self createBufferDataByType:[self getStrideTypes] indicesIntoNames:indicesIntoNames];
}

-(NSArray *)getStrideTypes
{
    const TGStrideType st = st_float3;

    if( _UVs )
    {
        if( _normals )
            return @[@(st),@(st_float2),@(st_float3)];
        else
            return @[@(st),@(st_float2)];
    }
    else
    {
        if( _normals )
            return @[@(st),@(st_float3)];
    }
    return @[@(st)];
}

-(void)createBufferDataByType:(NSArray *)strideTypes
             indicesIntoNames:(NSArray *)indicesIntoNames
{
    GeometryStats stats;
    [self getStats:&stats];
    
    TGVertexStride * strides;
    unsigned int     numStrides;
    void *           vertexData;
    unsigned int     numVertices;
    unsigned int *   indexData = NULL;
    unsigned int     numIndices;
    
    numStrides = [strideTypes count];
    
    strides = malloc(sizeof(TGVertexStride)*numStrides);
    
    for( int i = 0; i < numStrides; i++ )
    {
        TGVertexStride * stride = strides + i;
        TGStrideType type = [strideTypes[i] intValue];
        switch (type) {
            case st_float1:
                StrideInit1f(stride);
                break;
            case st_float2:
                StrideInit2f(stride);
                break;
            case st_float3:
                StrideInit3f(stride);
                break;
            case st_float4:
                StrideInit4f(stride);
                break;
#if DEBUG
            default:
                NSLog(@"Unknown StrideType");
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
