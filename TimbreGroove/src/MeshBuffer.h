//
//  TGBuffer.h
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"


static inline TGVertexStride * StrideInit2f(TGVertexStride * s)
{
    s->glType = GL_FLOAT;
    s->numSize = sizeof(float);
    s->numbersPerElement = 2;
    s->location = -1;
    s->indexIntoShaderNames = -1;
    s->strideType = st_float2;
    return s;
}

static inline TGVertexStride * StrideInit3f(TGVertexStride * s)
{
    StrideInit2f(s);
    s->numbersPerElement = 3;
    s->strideType = st_float3;
    return s;
}

static inline TGVertexStride * StrideInit4f(TGVertexStride * s)
{
    StrideInit2f(s);
    s->numbersPerElement = 4;
    s->strideType = st_float4;
    return s;
}

@class Shader;

/*
  supports interlaced buffers
*/
@interface MeshBuffer : NSObject

@property (nonatomic) TGDrawType  drawType;
@property (nonatomic) GLenum      usage;
@property (nonatomic) GLuint      glVBuffer;
@property (nonatomic) GLuint      glIBuffer;

+(GLsizei)calcDataSize: (TGVertexStride *)strides
          countStrides: (unsigned int)countStrides
           numVertices: (unsigned int)numVertices;

-(void)setData:(float *)data
       strides:(TGVertexStride *)strides
  countStrides:(unsigned int)countStrides
   numVertices: (unsigned int)numVertices;

-(void)setIndexData:(unsigned int *)data
            numIndices:(unsigned int)numIndices;

// for dynamic draw
-(void)setData: (float *)data;

-(void)getLocations:(Shader*)shader;

-(void)bind;
-(void)unbind;
-(void)draw;

-(NSArray *)indicesIntoShaderNames;

// TODO: this probably belongs somewhere else
-(bool)bindToTempLocation:(GLuint)location;

@end
