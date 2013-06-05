//
//  GridPlane.m
//  TimbreGroove
//
//  Created by victor on 1/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "GridPlane.h"

@interface GridPlane () {
    unsigned int _gridSize;
    float _width;
    GLKVector4 * _colors;
    int _numColors;
}

@end
@implementation GridPlane

+(id) gridWithIndicesIntoNames:(NSArray *)indicesIntoNames
{
    return [GridPlane gridWithWidth:2.0
                           andGrids:1
                andIndicesIntoNames:indicesIntoNames
                          andColors:NULL
                          numColors:0];
}

+(id) gridWithIndicesIntoNames:(NSArray *)indicesIntoNames
                     andColors:(GLKVector4 *)colors
                     numColors:(int)numColors
{
    return [GridPlane gridWithWidth:2.0
                           andGrids:1.0
                andIndicesIntoNames:indicesIntoNames
                          andColors:colors
                          numColors:numColors];
}

+(id) gridWithWidth:(float)width
           andGrids:(unsigned int)gridSize
andIndicesIntoNames:(NSArray *)indicesIntoNames
{
    return [GridPlane gridWithWidth:width
                           andGrids:gridSize
                andIndicesIntoNames:indicesIntoNames
                          andColors:NULL
                          numColors:0];
}

+(id) gridWithWidth:(float)width
           andGrids:(unsigned int)gridSize
andIndicesIntoNames:(NSArray *)indicesIntoNames
          andColors:(GLKVector4 *)colors
          numColors:(int)numColors
{
    GridPlane * gp = [[GridPlane alloc] init];
    if( gp )
    {
        gp->_gridSize = gridSize;
        gp->_width = width;
        gp->_colors = colors;
        gp->_numColors = numColors;
        [gp createWithIndicesIntoNames:indicesIntoNames];
    }
    return gp;
}

-(float)width
{
    return _width;
}

-(void)getStats:(GeometryStats *)stats
{
    unsigned int m = _gridSize + 1;
    stats->numVertices = m * m;
    stats->numIndices  = (_gridSize * _gridSize) * 6;
}

-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
{
    unsigned int i, n;
    GLfloat x, y, u, v;
    bool withUVs = self.UVs;
    bool withNormals = self.normals;
    bool withVerts = self.verticies;
    int colorCount = 0;
    
    float * pos = (float *)vertextData;
    float gridSize = _width / (float)_gridSize;
    for( i = 0; i < _gridSize+1; i++ )
    {
        x = -(_width/2.0) + (gridSize * i);
        u = (1.0f / _width) * (x + _width/2.0);
        for( n = 0; n < _gridSize+1; n++ )
        {
            y = -(_width/2.0) + gridSize * n;
            if( withVerts )
            {
                *pos++ = x;
                *pos++ = y;
                *pos++ = 0;
            }
            if( withUVs )
            {
                v = (1.0f / _width) * (y + _width/2.0);
                *pos++ = u; // * _gridSize;
                *pos++ = v; // * _gridSize;
            }
            if( withNormals )
            {
                *pos++ = 0;
                *pos++ = 0;
                *pos++ = 1.0;
            }
            if( _numColors )
            {
                GLKVector4 * color = _colors + colorCount++;
                *pos++ = color->r;
                *pos++ = color->g;
                *pos++ = color->b;
                *pos++ = color->a;
            }
        }
    }
    
    if( indexData )
    {
        unsigned int * pi = indexData;
        
        for( i = 0; i < _gridSize; i++ )
        {
            for( n = 0; n < _gridSize; n++)
            {
                unsigned int first = i * (_gridSize + 1) + n;
                unsigned int second = first + (_gridSize + 1);
                unsigned int third = first + 1;
                unsigned int fourth = second + 1;
                *pi++ = first;
                *pi++ = second;
                *pi++ = third;
                
                *pi++ = third;
                *pi++ = second;
                *pi++ = fourth;
            }
        }
    }
}

@end
