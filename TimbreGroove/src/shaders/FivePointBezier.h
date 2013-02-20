//
//  FivePointBezier
//  TimbreGroove
//
//  Created by victor on 2/15/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Shader.h"
#import "Geometry.h"

@interface FivePointBezier : Shader

/*
 
                -[3]-
               /     \
             /         \
          [2]          [4]
         /                \
     [1]/                  \[5]
 
   [1]   left
   [2]   leftController
   [3]   hiPoint
   [4]   rightController
   [5]   right
 
*/

@property (nonatomic) CGPoint left;
@property (nonatomic) CGPoint leftController;
@property (nonatomic) CGPoint hiPoint;
@property (nonatomic) CGPoint rightController;
@property (nonatomic) CGPoint right;

@property (nonatomic) GLKVector4 color;
@property (nonatomic) GLKMatrix4 pvm;

@property (nonatomic) GLKVector3 * controlPoints; // [5] no more, no less
@end

@interface FivePointBezierMesh : Geometry

@end