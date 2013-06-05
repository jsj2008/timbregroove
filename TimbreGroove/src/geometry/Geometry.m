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
    [self createBufferDataByStride:[self getStrideSizes:indicesIntoNames]
                  indicesIntoNames:indicesIntoNames];
}

-(NSArray *)getStrideSizes:(NSArray *)indeciesIntoNames
{
    return [indeciesIntoNames map:^id(NSNumber *num) {
        GenericVariables var = [num intValue];
        switch (var) {
            case gv_pos:
                _verticies = true;
                return @(3);
                break;
            case gv_normal:
                _normals = true;
                return @(3);
                break;
            case gv_uv:
                _UVs = true;
                return @(2);
            case gv_acolor:
                _acolors = true;
                return @(4);
            default:
                break;
        }
        return @(-1);
    }];
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
              indexData:indexData];
    
    [self setData:vertexData
          strides:strides
     countStrides:numStrides
      numVertices:numVertices
        indexData:indexData
       numIndices:numIndices];
    
    if( (TGGetLogLevel() & LLGeometry) != 0 )
    {
        printf("Geometry: \n");
        float * p = vertexData;
        for( int v = 0; v < numVertices; v++ )
        {
            VertexStride * stride = strides;
            for( int q = 0; q < numStrides; q++, stride++ )
            {
                printf("{ ");
                for( int x = 0; x < stride->numbersPerElement; x++ )
                {
                    if( x )
                        printf( ", ");
                    printf("%G",*p++);
                }
                printf("} ");
            }
            printf("\n");
        }
        printf("Triangle indecies:\n");
        for( int i = 0; i < numIndices; i++ )
        {
            printf("%d ", indexData[i]);
        }
    }
    
    free(strides);
    free(vertexData);
    if( indexData )
        free(indexData);
}

// for dynamic draw
-(void)resetVertices
{
    void * vertexData = malloc(self.bufferSize);
    [self getBufferData:vertexData indexData:NULL];
    [self setData:vertexData];
    free(vertexData);
}

-(void)getStats:(GeometryStats *)stats
{
    
}
-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
{
    
}
@end
