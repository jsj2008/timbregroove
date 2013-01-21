//
//  Cube.m
//  TimbreGroove
//
//  Created by victor on 1/21/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Cube.h"

@interface Cube () {
    float _width;
}

@end
@implementation Cube

+(id) cubeWithIndicesIntoNames:(NSArray *)indicesIntoNames
                      andDoUVs:(bool)UVs
                  andDoNormals:(bool)normals
{
    return [Cube cubeWithWidth:2.0  andIndicesIntoNames:indicesIntoNames
                           andDoUVs:UVs andDoNormals:normals];
}

+(id) cubeWithWidth:(float)width
andIndicesIntoNames:(NSArray *)indicesIntoNames
           andDoUVs:(bool)UVs
       andDoNormals:(bool)normals
{
    Cube * gp = [[Cube alloc] init];
    if( gp )
    {
        gp->_width = width;
        [gp createWithIndicesIntoNames:indicesIntoNames doUVs:UVs doNormals:normals];
    }
    return gp;
}

-(void)getStats:(GeometryStats *)stats
{
    stats->numVertices = 24;
    stats->numIndices  = 36;
}

-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
             withUVs:(bool)withUVs
         withNormals:(bool)withNormals
{
    static GLfloat verts[] =
    {
        -1, -1, -1,
        -1, -1,  1,
         1, -1,  1,
         1, -1, -1,
        -1,  1, -1,
        -1,  1,  1,
         1,  1,  1,
         1,  1, -1,
        -1, -1, -1,
        -1,  1, -1,
         1,  1, -1,
         1, -1, -1,
        -1, -1,  1,
        -1,  1,  1,
         1,  1,  1,
         1, -1,  1,
        -1, -1, -1,
        -1, -1,  1,
        -1,  1,  1,
        -1,  1, -1,
         1, -1, -1,
         1, -1,  1,
         1,  1,  1,
         1,  1, -1,
    };
    
    static GLfloat normals[] =
    {
        0, -1, 0,
        0, -1, 0,
        0, -1, 0,
        0, -1, 0,
        0, 1, 0,
        0, 1, 0,
        0, 1, 0,
        0, 1, 0,
        0, 0, -1,
        0, 0, -1,
        0, 0, -1,
        0, 0, -1,
        0, 0, 1,
        0, 0, 1,
        0, 0, 1,
        0, 0, 1,
        -1, 0, 0,
        -1, 0, 0,
        -1, 0, 0,
        -1, 0, 0,
        1, 0, 0,
        1, 0, 0,
        1, 0, 0,
        1, 0, 0,
    };
    
    static GLfloat UVs[] =
    {
        0, 0,
        0, 1,
        1, 1,
        1, 0,
        1, 0,
        1, 1,
        0, 1,
        0, 0,
        0, 0,
        0, 1,
        1, 1,
        1, 0,
        0, 0,
        0, 1,
        1, 1,
        1, 0,
        0, 0,
        0, 1,
        1, 1,
        1, 0,
        0, 0,
        0, 1,
        1, 1,
        1, 0,
    };
    
    float *pVerts = verts, *pNormals = normals, *pUVs = UVs, *pos = (float*)vertextData;
    
    for( int i = 0; i < 24; i++ )
    {
        *pos++ = *pVerts++;
        *pos++ = *pVerts++;
        *pos++ = *pVerts++;
        
        if( withUVs )
        {
            *pos++ = *pUVs++;
            *pos++ = *pUVs++;
        }
        
        if( withNormals )
        {
            *pos++ = *pNormals++;
            *pos++ = *pNormals++;
            *pos++ = *pNormals++;
        }
    }
    
    GLushort indices[] =
    {
        0, 2, 1,
        0, 3, 2,
        4, 5, 6,
        4, 6, 7,
        8, 9, 10,
        8, 10, 11,
        12, 15, 14,
        12, 14, 13,
        16, 17, 18,
        16, 18, 19,
        20, 23, 22,
        20, 22, 21
    };
    
    memcpy(indexData, indices, sizeof(indices));
}

@end
