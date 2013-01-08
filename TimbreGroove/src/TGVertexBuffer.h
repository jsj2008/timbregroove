//
//  TGBuffer.h
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"


static inline TGVertexStride * StrideInit2f(TGVertexStride * s, SVariables type)
{
    s->glType = GL_FLOAT;
    s->numSize = sizeof(float);
    s->numbersPerElement = 2;
    s->shaderAttrName = NULL;
    s->location = -1;
    s->tgVarType = type;
    return s;
}

static inline TGVertexStride * StrideInit3f(TGVertexStride * s, SVariables type)
{
    StrideInit2f(s,type);
    s->numbersPerElement = 3;
    return s;
}

static inline TGVertexStride * StrideInit4f(TGVertexStride * s, SVariables type)
{
    StrideInit2f(s,type);
    s->numbersPerElement = 4;
    return s;
}

@class Shader;

/*
  supports interlaced buffers
*/
@interface TGVertexBuffer : NSObject

@property (nonatomic) TGDrawType  drawType;
@property (nonatomic) GLuint      glVBuffer;
@property (nonatomic) GLuint      glIBuffer;

@property (nonatomic,readonly,getter=getSvTypes) NSArray * svTypes;


+(GLsizei)calcDataSize: (TGVertexStride *)strides
          countStrides: (unsigned int)countStrides
           numVertices: (unsigned int)numVertices;

-(void)setData:(float *)data
       strides:(TGVertexStride *)strides
  countStrides:(unsigned int)countStrides
   numVertices: (unsigned int)numVertices;

-(void)setIndexData:(unsigned int *)data
            numIndices:(unsigned int)numIndices;

-(void)getLocations:(Shader*)shader;

-(void)bind:(Shader *)shader;

-(void)draw;

// TODO: this probably belongs somewhere else
-(bool)assignMeshToShader:(Shader *)shader atLocation:(GLuint)location;

@end
