//
//  GenericCamera.m
//  TimbreGroove
//
//  Created by victor on 4/19/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "PainterCamera.h"
#import "Painter.h"
#import "GenericShader.h"
#import "Names.h"

@implementation PainterCamera {
    bool _gaveParams;
}

-(void)bind:(Shader *)shader object:(Node3d*)object
{
    GLKMatrix4 mvm = object.modelView;
    GLKMatrix4 pvm = GLKMatrix4Multiply(self.projectionMatrix, mvm);
    [shader writeToLocation:gv_pvm type:TG_MATRIX4 data:pvm.m];
}

-(void)unbind:(Shader *)shader{}

#define RAD_TURNS(f) (f * (M_PI / 180))

-(void)getParameters:(NSMutableDictionary *)parameters
{
    if( _gaveParams )
        return;
    
    parameters[kParamCameraRotationX] = [Parameter withBlock:^(float f) {
        GLKVector3 r = self.rotation;
        r.x += RAD_TURNS(f * 3);
        self.rotation = r;
    }];
    parameters[kParamCameraRotationY] = [Parameter withBlock:^(float f) {
        GLKVector3 r = self.rotation;
        r.y += RAD_TURNS(f * 3);
        self.rotation = r;
    }];
    parameters[kParamCameraRotationZ] = [Parameter withBlock:^(float f) {
        GLKVector3 r = self.rotation;
        r.z += RAD_TURNS(f * 3);
        self.rotation = r;
    }];
    parameters[kParamCameraZ] = [Parameter withBlock:^(float f) {
        GLKVector3 r = self.position;
        r.z += f * 3.0;
        self.position = r;
    }];
    
    parameters[kParamCameraReset] = [Parameter withBlock:^(CGPoint pt) {
        self.position = (GLKVector3){ 0, 0, CAMERA_DEFAULT_Z };
        self.rotation = (GLKVector3){ 0, 0, 0 };
    }];
    
    _gaveParams = true;
}

@end
