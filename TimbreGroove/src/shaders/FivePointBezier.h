//
//  FivePointBezier
//  TimbreGroove
//
//  Created by victor on 2/15/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Shader.h"
#import "Geometry.h"

#define BEZ_LEFT_PT       0
#define BEZ_LEFT_CTRL_PT  1
#define BEZ_HI_PT         2
#define BEZ_RIGHT_CTRL_PT 3
#define BEZ_RIGHT_PT      4

@interface FivePointBezier : Shader

/*
 
                -[2]-
               /     \
             /         \
          [1]          [3]
         /                \
     [0]/                  \[4]
 
   [0]   left
   [1]   leftController
   [2]   hiPoint
   [3]   rightController
   [4]   right
 
*/

@property (nonatomic) GLKVector4 color;
@property (nonatomic) GLKMatrix4 pvm;

@property (nonatomic) GLKVector3 * controlPoints; // [5] no more, no less
@end

@interface FivePointBezierMesh : Geometry

@end