//
//  TGBuffer.h
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"


static inline VertexStride * StrideInit2f(VertexStride * s)
{
    s->glType = GL_FLOAT;
    s->numSize = sizeof(float);
    s->numbersPerElement = 2;
    s->location = -1;
    s->indexIntoShaderNames = -1;
    return s;
}

static inline VertexStride * StrideInit3f(VertexStride * s)
{
    StrideInit2f(s);
    s->numbersPerElement = 3;
    return s;
}

static inline VertexStride * StrideInit4f(VertexStride * s)
{
    StrideInit2f(s);
    s->numbersPerElement = 4;
    return s;
}

static inline VertexStride * StrideInit1f(VertexStride * s)
{
    StrideInit2f(s);
    s->numbersPerElement = 1;
    return s;
}

@class Shader;

/*
  supports interlaced buffers
*/
@interface MeshBuffer : NSObject

@property (nonatomic) GLuint      drawType;
@property (nonatomic) GLenum      usage;
@property (nonatomic) bool        drawable;
@property (nonatomic) GLuint      vertextBufferId;
@property (nonatomic) GLuint      indexBufferId;
@property (nonatomic) GLuint      vbaId;

+(GLsizei)calcDataSize: (VertexStride *)strides
          countStrides: (unsigned int)countStrides
           numVertices: (unsigned int)numVertices;

-(void)setData:(float *)data
       strides:(VertexStride *)strides
  countStrides:(unsigned int)countStrides
   numVertices:(unsigned int)numVertices
     indexData:(unsigned int *)indexData
    numIndices:(unsigned int)numIndices;

-(void)setIndexData:(unsigned int *)data
            numIndices:(unsigned int)numIndices;

// for dynamic draw
-(void)setData: (float *)data;
@property (nonatomic,readonly) GLsizei bufferSize;

-(void)getLocations:(Shader*)shader;

-(void)bind;
-(void)unbind;
-(void)draw;

-(NSArray *)indicesIntoShaderNames;

// TODO: this probably belongs somewhere else
-(bool)bindToTempLocation:(GLuint)location;
-(void)bindToTempLocationVBA:(GLuint)location;

@end

@interface WireFrame : MeshBuffer
-(id)initWithIndexBuffer:(unsigned int *)indices
                    data:(float *)data
          geometryBuffer:(MeshBuffer *)buffer;
@end

@interface ColorBuffer : MeshBuffer
-(void)setDataWithRGBAs:(float *)rgba numColors:(unsigned int)numColors indexIntoNames:(int)indexIntoNames;
@end

