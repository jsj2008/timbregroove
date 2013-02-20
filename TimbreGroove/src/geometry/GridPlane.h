//
//  GridPlane.h
//  TimbreGroove
//
//  Created by victor on 1/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Geometry.h"

@interface GridPlane : Geometry

+(id) gridWithIndicesIntoNames:(NSArray *)indicesIntoNames
                      andDoUVs:(bool)UVs
                  andDoNormals:(bool)normals;

+(id) gridWithWidth:(float)width
           andGrids:(unsigned int)gridSize
andIndicesIntoNames:(NSArray *)indicesIntoNames
           andDoUVs:(bool)UVs
       andDoNormals:(bool)normals;

@property (nonatomic, readonly) float width;
@end
