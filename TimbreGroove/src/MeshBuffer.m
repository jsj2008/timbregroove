 //
//  TGBuffer.m
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "MeshBuffer.h"
#import "Shader.h"

#define MAX_STRIDES      8
#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface MeshBuffer()
{
@protected
    unsigned int   _numVertices;
    unsigned int   _numIndices;
    VertexStride   _strides[MAX_STRIDES];
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
        _indexBufferId = -1;
        _vertextBufferId = -1;
        _drawable = true;
    }
    
    return self;
}

-(void)draw
{
    if( _indexBufferId == -1 )
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
    glBindBuffer(GL_ARRAY_BUFFER, _vertextBufferId);
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
    
    glGenBuffers(1, &_vertextBufferId);
    TGLog(LLGLResource, @"created vertex buffer: %@ (%d) sz:%d numVrtx:%d",self, _vertextBufferId,bufferSize,numVertices);
    glBindBuffer(GL_ARRAY_BUFFER, _vertextBufferId);
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
    glGenBuffers(1, &_indexBufferId);
    TGLog(LLGLResource, @"created index buffer: %d numIndx:%d",_indexBufferId,numIndices);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBufferId);
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

   // glEnableVertexAttribArray(0);
}

-(void)bind
{
    if( _vertextBufferId != -1 )
    {
        glBindBuffer(GL_ARRAY_BUFFER, _vertextBufferId);
        [self setupBindings];
    }
    if( _indexBufferId != -1 )
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBufferId);
}

-(void)unbind
{
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    if( _indexBufferId != -1 )
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    for( int i = 0; i < _numStrides; i++ )
    {
        VertexStride * stride = _strides + i;
        glDisableVertexAttribArray(stride->location);
    }
}

// TODO: this probably belongs somewhere else
-(bool)bindToTempLocation:(GLuint)location
{
    VertexStride * stride = _strides; // WAHOO!! assume the first stride is position!!!    
    glBindBuffer(GL_ARRAY_BUFFER, _vertextBufferId);
    glEnableVertexAttribArray(location);
    glVertexAttribPointer( location,
                          stride->numbersPerElement,
                          stride->glType,
                          GL_FALSE,
                          _strideSize,
                          BUFFER_OFFSET(0));
    if( _indexBufferId != -1 )
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBufferId);
    return true;
}

-(void)dealloc
{
    if( glIsBuffer(_vertextBufferId))
        glDeleteBuffers(1, &_vertextBufferId);
    if( glIsBuffer(_indexBufferId))
        glDeleteBuffers(1, &_indexBufferId);
    TGLog(LLGLResource | LLObjLifetime, @"%@ Deleted buffers index (%d) and vertex (%d)",self,_indexBufferId,_vertextBufferId);
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

@implementation WireFrame

-(id)initWithIndexBuffer:(unsigned int *)indices
                    data:(float *)data
          geometryBuffer:(MeshBuffer *)buffer
{
    self = [super init];
    if( self )
    {
        unsigned int numIndices      = buffer->_numIndices;
        unsigned int numLineIndices = (numIndices / 3) * 6;
        unsigned int offset_line = 0;
        unsigned int * lineArray = malloc( numLineIndices * sizeof(unsigned int));
        for ( unsigned int f = 0; f < numIndices; f += 3)
        {
            lineArray[ offset_line++ ] = indices[f];
            lineArray[ offset_line++ ] = indices[f + 1];
            
            lineArray[ offset_line++ ] = indices[f + 1];
            lineArray[ offset_line++ ] = indices[f + 2];
            
            lineArray[ offset_line++ ] = indices[f + 2];
            lineArray[ offset_line++ ] = indices[f];
        }
        [self setData:data
              strides:buffer->_strides
         countStrides:buffer->_numStrides
          numVertices:buffer->_numVertices
            indexData:lineArray
           numIndices:numLineIndices];
 
        free(lineArray);
        
        self.drawType = GL_LINES;
    }
    return self;
}
@end
