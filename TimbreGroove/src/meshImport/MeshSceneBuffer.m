//
//  MeshSceneBuffer.m
//  TimbreGroove
//
//  Created by victor on 3/29/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "MeshSceneBuffer.h"

@implementation MeshSceneBuffer

-(id)initWithGeometryBuffer:(MeshGeometryBuffer *)bufferInfo
               andIndexData:(MeshGeometryIndexBuffer *)indexBuffer
     andIndexIntoShaderName:(int)iisn
{
    static VertexStrideType strideMap[] = { st_float1, st_float2, st_float3, st_float4 };
    self = [super init];
    if( self )
    {
        VertexStride stride;
        stride.glType = GL_FLOAT;
        stride.indexIntoShaderNames = iisn;
        stride.location = -1;
        stride.numbersPerElement = bufferInfo->stride;
        stride.numSize = sizeof(float);
        stride.strideType = strideMap[ bufferInfo->stride ];

        unsigned int * indexData  = indexBuffer ? indexBuffer->indexData  : NULL;
        unsigned int   numIndices = indexBuffer ? indexBuffer->numIndices : 0;
        
        [self setData:bufferInfo->data
              strides:&stride
         countStrides:1
          numVertices:bufferInfo->numElements
            indexData:indexData
           numIndices:numIndices];
    }
    return self;
}

@end
