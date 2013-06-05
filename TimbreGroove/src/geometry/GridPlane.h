//
//  GridPlane.h
//  TimbreGroove
//
//  Created by victor on 1/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Geometry.h"

@interface GridPlane : Geometry

+(id) gridWithIndicesIntoNames:(NSArray *)indicesIntoNames;

+(id) gridWithIndicesIntoNames:(NSArray *)indicesIntoNames
                     andColors:(GLKVector4 *)color
                     numColors:(int)numColors;

+(id) gridWithWidth:(float)width
           andGrids:(unsigned int)gridSize
andIndicesIntoNames:(NSArray *)indicesIntoNames;

@property (nonatomic, readonly) float width;
@end
