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
     andIndexIntoShaderName:(int)iisn
{
    self = [super init];
    if( self )
    {
        VertexStride stride;
        stride.glType = GL_FLOAT;
        stride.indexIntoShaderNames = iisn;
        stride.location = -1;
        stride.numbersPerElement = bufferInfo->stride;
        stride.numSize = sizeof(float);
        switch (stride.numbersPerElement) {
            case 1:
                stride.strideType = st_float1;
                break;
            case 2:
                stride.strideType = st_float2;
                break;
            case 3:
                stride.strideType = st_float3;
                break;
            case 4:
                stride.strideType = st_float4;
                break;
        };
        
        [self setData:bufferInfo->data
              strides:&stride
         countStrides:1
          numVertices:bufferInfo->numElements
            indexData:bufferInfo->indexData
           numIndices:bufferInfo->numIndices];
        
    }
    return self;
}

@end
