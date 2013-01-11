//
//  TGCamera.h
//  TimbreGroove
//
//  Created by victor on 12/13/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"

#define CAMERA_DEFAULT_NEAR           1.0f
#define CAMERA_DEFAULT_FAR            1000.0f
#define CAMERA_DEFAULT_frustum_ANGLE  45.0f
#define CAMERA_DEFAULT_Z              -100.0f


@interface TGCamera : NSObject

-(id)cloneCamera;

@property (nonatomic) GLKVector3 position;
@property (nonatomic) GLKVector3 rotation;

@property (nonatomic) float z;

-(void)setPerspective: (float)near far:(float)far frustumAngle:(float)degrees viewWidth:(float)viewWidth viewHeight:(float)viewHeight;
-(void)setPerspectiveForViewWidth:(float)viewWidth andHeight:(float)viewHeight;

-(GLKMatrix4) projectionMatrix;

@end