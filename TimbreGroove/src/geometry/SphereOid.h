//
//  GridPlane.h
//  TimbreGroove
//
//  Created by victor on 1/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Geometry.h"

@interface SphereOid : Geometry

+(id) sphereWithdIndicesIntoNames:(NSArray *)indicesIntoNames;

+(id) sphereWithRadius:(float)radius
              andLongs:(unsigned int)longs
               andLats:(unsigned int)lats
   andIndicesIntoNames:(NSArray *)indicesIntoNames;

@end
