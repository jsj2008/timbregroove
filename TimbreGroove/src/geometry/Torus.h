//
//  Torus.h
//  TimbreGroove
//
//  Created by victor on 1/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Geometry.h"

@interface Torus : Geometry

+(id) torusWithIndicesIntoNames:(NSArray *)indicesIntoNames
                         andDoUVs:(bool)UVs
                     andDoNormals:(bool)normals;

+(id) torusWithRadius:(float)radius
        andTubeRadius:(float)tubeRadius
          andGridStop:(unsigned int)gridStop
  andIndicesIntoNames:(NSArray *)indicesIntoNames
             andDoUVs:(bool)UVs
         andDoNormals:(bool)normals;

@end
