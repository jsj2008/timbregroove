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
    s->shaderAttr = -1;
    s->tgVarType = type;
    return s;
}

static inline TGVertexStride * StrideInit3f(TGVertexStride * s, SVariables type)
{
    s->glType = GL_FLOAT;
    s->numSize = sizeof(float);
    s->numbersPerElement = 3;
    s->shaderAttr = -1;
    s->tgVarType = type;
    return s;
}

static inline TGVertexStride * StrideInit4f(TGVertexStride * s, SVariables type)
{
    s->glType = GL_FLOAT;
    s->numSize = sizeof(float);
    s->numbersPerElement = 4;
    s->shaderAttr = -1;
    s->tgVarType = type;
    return s;
}

@class TGShader;

/*
  supports interlaced buffers
*/
@interface TGVertexBuffer : NSObject

@property (nonatomic) TGDrawType drawType;
@property (nonatomic) GLuint     glindex;

-(void)setData:(float *)data
       strides:(TGVertexStride *)strides
  countStrides:(unsigned int)countStrides
       numElem: (unsigned int)numElem
        shader:(TGShader*)shader;

-(void)setBuffer:(TGShader *)shader;

-(void)draw;

@end
