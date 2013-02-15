//
//  Line.h
//  TimbreGroove
//
//  Created by victor on 2/14/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Geometry.h"

@interface Line : Geometry

- (id)initWithIndicesIntoNames:(NSArray *)indicesIntoNames
                     isDynamic:(bool)dynamic
                       spacing:(float)spacing;

@property (nonatomic) float * heightOffsets;
@end
