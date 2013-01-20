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
}

@end
@implementation GridPlane

+(id) gridWithIndicesIntoNames:(NSArray *)indicesIntoNames
                      andDoUVs:(bool)UVs
                  andDoNormals:(bool)normals
{
    return [GridPlane gridWithWidth:2.0 andGrids:1 andIndicesIntoNames:indicesIntoNames
                           andDoUVs:UVs andDoNormals:normals];
}

+(id) gridWithWidth:(float)width
           andGrids:(unsigned int)gridSize
andIndicesIntoNames:(NSArray *)indicesIntoNames
           andDoUVs:(bool)UVs
       andDoNormals:(bool)normals
{
    GridPlane * gp = [[GridPlane alloc] init];
    if( gp )
    {
        gp->_gridSize = gridSize;
        gp->_width = width;
        [gp createWithIndicesIntoNames:indicesIntoNames doUVs:UVs doNormals:normals];
    }
    return gp;
}

-(void)getStats:(GeometryStats *)stats
{
    unsigned int m = _gridSize + 1;
    stats->numVertices = m * m;
    stats->numIndices  = (_gridSize * _gridSize) * 6;
}

-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
             withUVs:(bool)withUVs
         withNormals:(bool)withNormals
{
    unsigned int i, n;
    GLfloat x, y, u, v;

    float * pos = (float *)vertextData;
    float gridSize = _width / (float)_gridSize;
    for( i = 0; i < _gridSize+1; i++ )
    {
        x = -(_width/2.0) + (gridSize * i);
        u = (1.0f / _width) * (x + _width/2.0);
        for( n = 0; n < _gridSize+1; n++ )
        {
            y = -(_width/2.0) + gridSize * n;
            *pos++ = x;
            *pos++ = y;
            *pos++ = 0;
            if( withUVs )
            {
                v = (1.0f / _width) * (y + _width/2.0);
                *pos++ = u;
                *pos++ = v;
            }
            if( withNormals )
            {
                *pos++ = 0;
                *pos++ = 0;
                *pos++ = 1.0;
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
