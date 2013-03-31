 //
//  TGBuffer.m
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "MeshBuffer.h"
#import "Shader.h"

#define MAX_STRIDES      4
#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface MeshBuffer()
{
    unsigned int   _numVertices;
    unsigned int   _numIndices;
    VertexStride _strides[MAX_STRIDES];
    unsigned int   _numStrides;
    unsigned int   _strideSize;
    GLsizei        _bufferSize;
}
@end;

@implementation MeshBuffer

-(MeshBuffer *)init
{
    if( (self = [super init]) )
    {
        _drawType = GL_TRIANGLES;
        _usage = GL_STATIC_DRAW;
        _glIBuffer = -1;
        _drawable = true;
    }
    
    return self;
}

-(void)draw
{
    if( _glIBuffer == -1 )
        glDrawArrays(_drawType, 0, _numVertices);
    else
        glDrawElements(_drawType,_numIndices,GL_UNSIGNED_INT,(void*)0);
}

+(GLsizei)calcDataSize: (VertexStride *)strides
          countStrides: (unsigned int)countStrides
           numVertices: (unsigned int)numVertices
{
    GLsizei size = 0;

    for( int i = 0; i < countStrides; i++ )
    {
        VertexStride * stride = strides + i;

        size += (stride->numSize * stride->numbersPerElement * numVertices);
    }
    
    return size;
}

-(GLsizei)bufferSize
{
    return _bufferSize;
}

-(void)getLocations:(Shader*)shader
{
    for( int i = 0; i < _numStrides; i++ )
    {
        VertexStride * stride = _strides + i;
        stride->location = [shader location:stride->indexIntoShaderNames];
    }    
}

-(NSArray *)indicesIntoShaderNames
{
    NSMutableArray * arr = [NSMutableArray new];
    for( int i = 0; i < _numStrides; i++ )
    {
        VertexStride * stride = _strides + i;
        [arr addObject:@(stride->indexIntoShaderNames)];
    }
    return arr;
}

-(void)setData: (float *)data
{
    glBindBuffer(GL_ARRAY_BUFFER, _glVBuffer);
    glBufferData(GL_ARRAY_BUFFER, _bufferSize, data, _usage);
}

-(void)setData: (float *)data
       strides: (VertexStride *)strides
  countStrides: (unsigned int)countStrides
   numVertices: (unsigned int)numVertices
     indexData:(unsigned int *)indexData
    numIndices:(unsigned int)numIndices
{
    
#if DEBUG
    if( countStrides > MAX_STRIDES )
    {
        TGLog(LLShitsOnFire, @"Too many strides");
        exit(1);
    }
#endif
    
    GLsizei strideSize = 0;
    for( int i = 0; i < countStrides; i++ )
    {
        VertexStride * stride = strides + i;
        strideSize += (stride->numSize * stride->numbersPerElement);
    }

    GLsizei bufferSize = _bufferSize = strideSize * numVertices;
    
    glGenBuffers(1, &_glVBuffer);
    TGLog(LLGLResource, @"created vertex buffer: %@ (%d) sz:%d numVrtx:%d",self, _glVBuffer,bufferSize,numVertices);
    glBindBuffer(GL_ARRAY_BUFFER, _glVBuffer);
    glBufferData(GL_ARRAY_BUFFER, bufferSize, data, _usage);
    
    _strideSize = strideSize;
    _numVertices = numVertices;
    memcpy(_strides, strides, countStrides * sizeof(VertexStride));
    _numStrides = countStrides;
    
    if( indexData )
       [self setIndexData:indexData numIndices:numIndices];
    
  //  glBindVertexArrayOES(0);
}

-(void)setIndexData:(unsigned int *)data numIndices:(unsigned int)numIndices
{
    _numIndices = numIndices;
    glGenBuffers(1, &_glIBuffer);
    TGLog(LLGLResource, @"created index buffer: %d numIndx:%d",_glIBuffer,numIndices);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _glIBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, numIndices * sizeof(unsigned int), data, _usage);
}

-(void)setupBindings
{
    unsigned int strideOffset = 0;
    
    for( int i = 0; i < _numStrides; i++ )
    {
        VertexStride * stride = _strides + i;
        glEnableVertexAttribArray(stride->location);
        glVertexAttribPointer( stride->location,
                              stride->numbersPerElement,
                              stride->glType,
                              GL_FALSE,
                              _strideSize,
                              BUFFER_OFFSET(strideOffset));
        
        strideOffset += (stride->numSize * stride->numbersPerElement);
    }

    glEnableVertexAttribArray(0);
}

-(void)bind
{
    glBindBuffer(GL_ARRAY_BUFFER, _glVBuffer);
    [self setupBindings];
    
    if( _glIBuffer != -1 )
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _glIBuffer);
}

-(void)unbind
{
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    if( _glIBuffer != -1 )
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

}

// TODO: this probably belongs somewhere else
-(bool)bindToTempLocation:(GLuint)location
{
    VertexStride * stride = _strides; // WAHOO!! assume the first stride is position!!!    
    glBindBuffer(GL_ARRAY_BUFFER, _glVBuffer);
    glEnableVertexAttribArray(location);
    glVertexAttribPointer( location,
                          stride->numbersPerElement,
                          stride->glType,
                          GL_FALSE,
                          _strideSize,
                          BUFFER_OFFSET(0));
    if( _glIBuffer != -1 )
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _glIBuffer);
    return true;
}

-(void)dealloc
{
    if( glIsBuffer(_glVBuffer))
        glDeleteBuffers(1, &_glVBuffer);
    if( glIsBuffer(_glIBuffer))
        glDeleteBuffers(1, &_glIBuffer);
    TGLog(LLGLResource | LLObjLifetime, @"%@ Deleted buffers index (%d) and vertex (%d)",self,_glIBuffer,_glVBuffer);
}
@end

@implementation ColorBuffer

-(void)setDataWithRGBAs:(float *)rgba
              numColors:(unsigned int)numColors
         indexIntoNames:(int)indexIntoNames
{
    VertexStride stride;
    StrideInit4f(&stride);
    stride.indexIntoShaderNames = indexIntoNames;
    [self setData:rgba strides:&stride countStrides:1 numVertices:numColors indexData:NULL numIndices:0];
    self.drawable = false;
}
@end