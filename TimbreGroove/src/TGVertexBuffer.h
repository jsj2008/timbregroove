//
//  TGBuffer.h
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    TG_POINTS = GL_POINTS, // etc.
    TG_LINES,
    TG_LINE_LOOP, 
    TG_LINE_STRIP,
    TG_TRIANGLES,      // default
    TG_TRIANGLE_STRIP,
    TG_TRIANGLE_FAN
} TGDrawType;

typedef struct {
    unsigned int glType; // e.g. GL_FLOAT
    unsigned int numSize; // e.g. sizeof(float)
    unsigned int numbersPerElement;
    const char * shaderAttrName;
    GLuint       shaderAttr;
} TGVertexStride;

static inline TGVertexStride * StrideInit3fv(TGVertexStride * s, const char * attrName)
{
    s->glType = GL_FLOAT;
    s->numSize = sizeof(float);
    s->numbersPerElement = 3;
    s->shaderAttr = -1;
    s->shaderAttrName = attrName;
    return s;
}

@class TGShader;

/*
  supports interlaced buffers
*/
@interface TGVertexBuffer : NSObject

@property (nonatomic) TGDrawType drawType;
@property (nonatomic) GLuint glindex;

-(void)setData:(float *)data
       strides:(TGVertexStride *)strides
  countStrides:(unsigned int)countStrides
       numElem: (unsigned int)numElem
        shader:(TGShader*)shader;

-(void)draw;

@end
