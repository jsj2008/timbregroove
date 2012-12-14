//
//  TGBuffer.m
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGVertexBuffer.h"
#import "TGShader.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface TGVertexBuffer()
{
    unsigned int _numElem;
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
    glDrawArrays(self.drawType, 0, _numElem);
}

-(void)setData: (float *)data
       strides: (TGVertexStride *)strides
  countStrides: (unsigned int)countStrides
       numElem: (unsigned int)numElem
        shader: (TGShader*)shader;
{
    _numElem = numElem;
    
    int i;
    GLsizei strideSize = 0;
    for( i = 0; i < countStrides; i++ )
    {
        TGVertexStride * stride = strides + i;
        strideSize += (stride->numSize * stride->numbersPerElement);
        if( stride->shaderAttr == -1 && stride->shaderAttrName != NULL )
             stride->shaderAttr = glGetAttribLocation(shader.program, stride->shaderAttrName);
    }

    GLsizei bufferSize = strideSize * numElem;
    
    glGenBuffers(1, &_glindex);
    glBindBuffer(GL_ARRAY_BUFFER, _glindex);
    glBufferData(GL_ARRAY_BUFFER, bufferSize, data, GL_STATIC_DRAW);
    
    unsigned int strideOffset = 0;
    
    [shader use];
    
    for( i = 0; i < countStrides; i++ )
    {
        TGVertexStride * stride = strides + i;
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
