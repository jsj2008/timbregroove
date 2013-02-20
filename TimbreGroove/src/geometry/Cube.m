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
    CubeTextureWrap _wrapType;
}

@end
@implementation Cube

+(id) cubeWithIndicesIntoNames:(NSArray *)indicesIntoNames
                      andDoUVs:(bool)UVs
                  andDoNormals:(bool)normals
                      wrapType:(CubeTextureWrap)wrapType
{
    return [Cube cubeWithWidth:2.0  andIndicesIntoNames:indicesIntoNames
                      andDoUVs:UVs andDoNormals:normals
                      wrapType:wrapType];
}

+(id) cubeWithWidth:(float)width
andIndicesIntoNames:(NSArray *)indicesIntoNames
           andDoUVs:(bool)UVs
       andDoNormals:(bool)normals
           wrapType:(CubeTextureWrap)wrapType
{
    Cube * gp = [[Cube alloc] init];
    if( gp )
    {
        gp->_wrapType = wrapType;
        gp->_width = width;
        [gp createWithIndicesIntoNames:indicesIntoNames doUVs:UVs doNormals:normals];
    }
    return gp;
}

+(id) cubeWithIndicesIntoNames:(NSArray *)indicesIntoNames
                      andDoUVs:(bool)UVs
                  andDoNormals:(bool)normals
{
    return [Cube cubeWithWidth:2.0  andIndicesIntoNames:indicesIntoNames
                           andDoUVs:UVs andDoNormals:normals
            wrapType:kCubeWrapRepeat];
}

+(id) cubeWithWidth:(float)width
andIndicesIntoNames:(NSArray *)indicesIntoNames
           andDoUVs:(bool)UVs
       andDoNormals:(bool)normals
{
    return [Cube cubeWithWidth:width  andIndicesIntoNames:indicesIntoNames
                      andDoUVs:UVs andDoNormals:normals
                      wrapType:kCubeWrapRepeat];
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
    static GLfloat vWrapVerts[] =
    {
        -1, -1, -1,        0.75, 0,    // 0   bottom
        -1, -1,  1,        0.75, 1,
        1, -1,  1,        1, 1,
        1, -1, -1,        1, 0,
        
        -1,  1, -1,        0.25, 1,    // 4 top
        -1,  1,  1,        0.25, 0,
        1,  1,  1,        0.50, 0,
        1,  1, -1,        0.50, 1,
        
        -1, -1, -1,        0.50, 1,    // 8 back
        -1,  1, -1,        0.50, 0,
        1,  1, -1,        0.75, 0,
        1, -1, -1,        0.75, 1,
        
        -1, -1,  1,        0, 0,    // 12 front
        -1,  1,  1,        0, 1,
        1,  1,  1,       0.25, 1,
        1, -1,  1,       0.25, 0,
        
        -1, -1, -1,        0.75, 0,    // 16 leftXX
        -1, -1,  1,        1, 0,
        -1,  1,  1,        1, 1,
        -1,  1, -1,        0.75, 1,
        
        1, -1, -1,        0.50, 0,    // 20 rightXX
        1, -1,  1,        0.25, 0,
        1,  1,  1,        0.25, 1,
        1,  1, -1,        0.50, 1
    };
    
    static GLfloat hWrapVerts[] =
    {
        -1, -1, -1,        0.75, 0,    // 0   bottom
        -1, -1,  1,        0.75, 1,
        1, -1,  1,        1, 1,
        1, -1, -1,        1, 0,
        
        -1,  1, -1,        0.50, 1,    // 4 top
        -1,  1,  1,        0.50, 0,
        1,  1,  1,        0.75, 0,
        1,  1, -1,        0.75, 1,
        
        -1, -1, -1,        0.75, 0,    // 8 back
        -1,  1, -1,        0.75, 1,
        1,  1, -1,        0.50, 1,
        1, -1, -1,        0.50, 0,
        
        -1, -1,  1,        0, 0,    // 12 front
        -1,  1,  1,        0, 1,
        1,  1,  1,       0.25, 1,
        1, -1,  1,       0.25, 0,
        
        -1, -1, -1,        0.75, 0,    // 16 left
        -1, -1,  1,        1, 0,
        -1,  1,  1,        1, 1,
        -1,  1, -1,        0.75, 1,
        
        1, -1, -1,        0.50, 0,    // 20 right
        1, -1,  1,        0.25, 0,
        1,  1,  1,        0.25, 1,
        1,  1, -1,        0.50, 1
    };

    
    static GLfloat repeatVerts[] =
    {
        -1, -1, -1,        0, 0,    // 0   bottom
        -1, -1,  1,        0, 1,
        1, -1,  1,        1, 1,
        1, -1, -1,        1, 0,
        
        -1,  1, -1,        0, 1,    // 4 top
        -1,  1,  1,        1, 0,
        1,  1,  1,        0, 0,
        1,  1, -1,        0, 1,
        
        -1, -1, -1,        1, 0,    // 8 back
        -1,  1, -1,        1, 1,
        1,  1, -1,        0, 1,
        1, -1, -1,        0, 0,
        
        -1, -1,  1,        0, 0,    // 12 front
        -1,  1,  1,        0, 1,
        1,  1,  1,       1, 1,
        1, -1,  1,       1, 0,
        
        -1, -1, -1,        0, 0,    // 16 left
        -1, -1,  1,        1, 0,
        -1,  1,  1,        1, 1,
        -1,  1, -1,        0, 1,
        
        1, -1, -1,        1, 0,    // 20 right
        1, -1,  1,        0, 0,
        1,  1,  1,        0, 1,
        1,  1, -1,        1, 1
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
    
    float *pVerts;
    
    if( _wrapType == kCubeWrapHorizontal )
        pVerts = hWrapVerts;
    else if( _wrapType == kCubeWrapVertical )
        pVerts = vWrapVerts;
    else if( _wrapType == kCubeWrapRepeat )
        pVerts = repeatVerts;
    
    float *pNormals = normals,
          *pos = (float*)vertextData,
          w = _width / 2.0;
    
    for( int i = 0; i < 24; i++ )
    {
        *pos++ = *pVerts++ * w;
        *pos++ = *pVerts++ * w;
        *pos++ = *pVerts++ * w;
        
        if( withUVs )
        {
            *pos++ = *pVerts++; // *pUVs++;
            *pos++ = *pVerts++;
        }
        else
        {
            pVerts++;pVerts++;
        }
        
        if( withNormals )
        {
            *pos++ = *pNormals++;
            *pos++ = *pNormals++;
            *pos++ = *pNormals++;
        }
    }
    
    unsigned int indices[] =
    {
        0, 2, 1,   // bottom
        0, 3, 2,
        
        4, 5, 6,   // top
        4, 6, 7,
        
        8, 9, 10,   // back
        8, 10, 11,
        
        12, 15, 14, // front
        12, 14, 13,
        
        16, 17, 18,  // left
        16, 18, 19,
        
        20, 23, 22,  // right
        20, 22, 21
    };
    
    if( indexData )
        memcpy(indexData, indices, sizeof(indices));
}

@end
