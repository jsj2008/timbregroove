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
    TGVertexStride _strides[MAX_STRIDES];
    unsigned int   _numStrides;
    unsigned int   _strideSize;
    NSMutableArray * __svTypes;
}
@end;

@implementation MeshBuffer

-(MeshBuffer *)init
{
    if( (self = [super init]) )
    {
        _drawType = GL_TRIANGLES;
        _glIBuffer = -1;
        __svTypes = [NSMutableArray new];
    }
    
    return self;
}

-(NSArray *)getSvTypes
{
    return __svTypes;
}

-(void)draw
{
    if( _glIBuffer == -1 )
    {
        glDrawArrays(_drawType, 0, _numVertices);
    }
    else
    {
        glDrawElements(_drawType,_numIndices,GL_UNSIGNED_INT,(void*)0);
    }
}

+(GLsizei)calcDataSize: (TGVertexStride *)strides
          countStrides: (unsigned int)countStrides
           numVertices: (unsigned int)numVertices
{
    GLsizei size = 0;

    for( int i = 0; i < countStrides; i++ )
    {
        TGVertexStride * stride = strides + i;

        size += (stride->numSize * stride->numbersPerElement * numVertices);
    }
    
    return size;
}

-(void)getLocations:(Shader*)shader
{
    for( int i = 0; i < _numStrides; i++ )
    {
        TGVertexStride * stride = _strides + i;
        if( !stride->shaderAttrName )
            stride->location = [shader location:stride->tgVarType];
        else
            stride->location = glGetAttribLocation(shader.program, stride->shaderAttrName);        
    }
}

-(void)setData: (float *)data
       strides: (TGVertexStride *)strides
  countStrides: (unsigned int)countStrides
   numVertices: (unsigned int)numVertices
{
    
#if DEBUG
    if( countStrides > MAX_STRIDES )
    {
        NSLog(@"Too many strides");
        exit(1);
    }
#endif
    
    GLsizei strideSize = 0;
    for( int i = 0; i < countStrides; i++ )
    {
        TGVertexStride * stride = strides + i;
        strideSize += (stride->numSize * stride->numbersPerElement);
        [__svTypes addObject:@(stride->tgVarType)];
    }

    GLsizei bufferSize = strideSize * numVertices;
    
    glGenBuffers(1, &_glVBuffer);
    NSLog(@"created vertex buffer: %d",_glVBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _glVBuffer);
    glBufferData(GL_ARRAY_BUFFER, bufferSize, data, GL_STATIC_DRAW);
    
    _strideSize = strideSize;
    _numVertices = numVertices;
    memcpy(_strides, strides, countStrides * sizeof(TGVertexStride));
    _numStrides = countStrides;
}

-(void)setIndexData:(unsigned int *)data numIndices:(unsigned int)numIndices
{
    _numIndices = numIndices;
    glGenBuffers(1, &_glIBuffer);
    NSLog(@"created index buffer: %d",_glIBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _glIBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, numIndices * sizeof(unsigned int), data, GL_STATIC_DRAW);
}

-(void)bind
{
    glBindBuffer(GL_ARRAY_BUFFER, _glVBuffer);
    
    unsigned int strideOffset = 0;
    
    for( int i = 0; i < _numStrides; i++ )
    {
        TGVertexStride * stride = _strides + i;
        glEnableVertexAttribArray(stride->location);
        glVertexAttribPointer( stride->location,
                              stride->numbersPerElement,
                              stride->glType,
                              GL_FALSE,
                              _strideSize,
                              BUFFER_OFFSET(strideOffset));
        
        strideOffset += (stride->numSize * stride->numbersPerElement);
    }
    
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
-(bool)assignMeshToShader:(Shader *)shader atLocation:(GLuint)location
{
    unsigned int     strideOffset = 0;
    TGVertexStride * stride;
    int i;
    for( i = 0; i < _numStrides; i++ )
    {
        stride = _strides + i;
        if( stride->tgVarType == sv_pos )
            break;
        strideOffset += (stride->numSize * stride->numbersPerElement);
    }

    if( i == _numStrides )
        return false;
    
    glBindBuffer(GL_ARRAY_BUFFER, _glVBuffer);
    glEnableVertexAttribArray(location);
    glVertexAttribPointer( location,
                          stride->numbersPerElement,
                          stride->glType,
                          GL_FALSE,
                          _strideSize,
                          BUFFER_OFFSET(strideOffset));
    return true;
}

-(void)dealloc
{
    if( glIsBuffer(_glVBuffer))
        glDeleteBuffers(1, &_glVBuffer);
    if( glIsBuffer(_glIBuffer))
        glDeleteBuffers(1, &_glIBuffer);
    NSLog(@"Deleted buffers %d/%d",_glIBuffer,_glVBuffer);
    _glIBuffer = -1;
    _glVBuffer = 0;
}
@end
