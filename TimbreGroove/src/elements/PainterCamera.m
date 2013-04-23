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

@implementation PainterCamera

-(void)bind:(Shader *)shader object:(Painter*)object
{
    GLKMatrix4 mvm = object.modelView;
    GLKMatrix4 pvm = GLKMatrix4Multiply(self.projectionMatrix, mvm);
    [shader writeToLocation:gv_pvm type:TG_MATRIX4 data:pvm.m];
    [shader writeToLocation:gv_mvm type:TG_MATRIX4 data:mvm.m];
}

-(void)unbind:(Shader *)shader{}
@end
