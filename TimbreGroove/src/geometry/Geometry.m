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
    if( _UVs )
    {
        if( _normals )
            return @[@(st_float3),@(st_float2),@(st_float3)];
        else
            return @[@(st_float3),@(st_float2)];
    }
    else
    {
        if( _normals )
            return @[@(st_float3),@(st_float3)];
    }
    return @[@(st_float3)];
}

-(void)createBufferDataByType:(NSArray *)strideTypes
             indicesIntoNames:(NSArray *)indicesIntoNames
{
    GeometryStats stats;
    [self getStats:&stats];
    
    TGGenericElementParams params;
    
    memset(&params, 0, sizeof(params));
    
    params.numStrides = [strideTypes count];
    
    params.strides = malloc(sizeof(TGVertexStride)*params.numStrides);
    
    for( int i = 0; i < params.numStrides; i++ )
    {
        TGVertexStride * stride = params.strides + i;
        TGStrideType type = [strideTypes[i] intValue];
        switch (type) {
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
    
    params.numVertices = stats.numVertices;
    params.numIndices  = stats.numIndices;
    GLsizei sz = [MeshBuffer calcDataSize:params.strides countStrides:params.numStrides numVertices:params.numVertices];
    params.vertexData = malloc(sz);
    if( params.numIndices > 0 )
        params.indexData = malloc( sizeof(unsigned int) * params.numIndices );
    
    [self getBufferData:params.vertexData
              indexData:params.indexData
                withUVs:_UVs
            withNormals:_normals];
    
    [self setData:params.vertexData
          strides:params.strides
     countStrides:params.numStrides
      numVertices:params.numVertices];
    
    if( params.indexData )
    {
        [self setIndexData:params.indexData
                numIndices:params.numIndices];
    }
    
    free(params.strides);
    free(params.vertexData);
    if( params.indexData )
        free(params.indexData);
}

-(void)getStats:(GeometryStats *)stats
{
    
}
-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
             withUVs:(bool)withUVs
         withNormals:(bool)withNormals;
{
    
}
@end
