//
//  TGBuffer.m
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGVertexBuffer.h"
#import "TGShader.h"

#define MAX_STRIDES      4
#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface TGVertexBuffer()
{
    unsigned int   _numElem;
    TGVertexStride _strides[MAX_STRIDES];
    unsigned int   _numStrides;
}
@end;

@implementation TGVertexBuffer

-(TGVertexBuffer *)init
{
    if( (self = [super init]) )
    {
        _drawType = GL_TRIANGLES;
    }
    
    return self;
}

-(void)draw
{
    glDrawArrays(_drawType, 0, _numElem);
}

-(void)setData: (float *)data
       strides: (TGVertexStride *)strides
  countStrides: (unsigned int)countStrides
       numElem: (unsigned int)numElem
        shader: (TGShader*)shader
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
        if( !stride->shaderAttrName )
            stride->shaderAttr = [shader location:stride->tgVarType];
        else
            stride->shaderAttr = glGetAttribLocation(shader.program, stride->shaderAttrName);
    }

    GLsizei bufferSize = strideSize * numElem;
    
    glGenBuffers(1, &_glindex);
    glBindBuffer(GL_ARRAY_BUFFER, _glindex);
    glBufferData(GL_ARRAY_BUFFER, bufferSize, data, GL_STATIC_DRAW);
    
    _numElem = numElem;
    memcpy(_strides, strides, countStrides * sizeof(TGVertexStride));
    _numStrides = countStrides;
    
  //  [self setBuffer:shader];
}

-(void)setBuffer:(TGShader *)shader
{
    unsigned int strideOffset = 0;
    
    [shader use];
    glBindBuffer(GL_ARRAY_BUFFER, _glindex);
    
    GLsizei strideSize = 0;
    for( int i = 0; i < _numStrides; i++ )
    {
        TGVertexStride * stride = _strides + i;
        strideSize += (stride->numSize * stride->numbersPerElement);
    }
    
    
    for( int i = 0; i < _numStrides; i++ )
    {
        TGVertexStride * stride = _strides + i;
        glEnableVertexAttribArray(stride->shaderAttr);
        glVertexAttribPointer( stride->shaderAttr,
                               stride->numbersPerElement,
                               stride->glType,
                               GL_FALSE,
                               strideSize,
                               BUFFER_OFFSET(strideOffset));
        strideOffset += (stride->numSize * stride->numbersPerElement);
    }
}
@end
