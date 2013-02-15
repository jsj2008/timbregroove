//
//  Line.m
//  TimbreGroove
//
//  Created by victor on 2/14/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Line.h"

@interface Line () {
    float _spacing;
    float _width;
    float _height;
}
@end

@implementation Line

- (id)initWithIndicesIntoNames:(NSArray *)indicesIntoNames
                     isDynamic:(bool)dynamic
                       spacing:(float)spacing;
{
    self = [super init];
    if (self) {
        if( dynamic )
            self.usage = GL_DYNAMIC_DRAW;
        _spacing = spacing;
        _width = 2.0;
        _height = 2.0;
        self.drawType = TG_LINE_STRIP; // TG_POINTS;
        [self createWithIndicesIntoNames:indicesIntoNames
                                   doUVs:false
                               doNormals:false];
    }
    return self;
}

-(void)getStats:(GeometryStats *)stats
{
    stats->numVertices = _spacing + 1;
    stats->numIndices  = 0;
}

-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
             withUVs:(bool)withUVs
         withNormals:(bool)withNormals
{
    unsigned int i;
    GLfloat x;
    
    float * pos = (float *)vertextData;
    float gridSize = _width / _spacing;
    for( i = 0; i < _spacing+1; i++ )
    {
        x = -(_width/2.0) + (gridSize * i);
        
        *pos++ = x;
        *pos++ = _heightOffsets ? _heightOffsets[i] * _height : 0;
        *pos++ = 0;
        if( withNormals )
        {
            *pos++ = 0;
            *pos++ = 0;
            *pos++ = 1.0;
        }
    }
    
}

@end
