//
//  Cloud.m
//  TimbreGroove
//
//  Created by victor on 1/19/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Cloud.h"
#import "TG3dObject.h"

/*
 attribute vec4 position;
 attribute vec3 normal;
 uniform mat4 modelViewProjectionMatrix;
 uniform mat4 modelViewMatrix;
 uniform mat3 normalMatrix;
uniform float time;
 uniform vec4 materialDiffuseColor0;
 uniform vec4 materialDiffuseColor1;

*/

const char * _cloud_names[] = {
    "position",
    "normal",
    "modelViewProjectionMatrix",
    "modelViewMatrix",
    "normalMatrix",
    "time"
};

const char * _cloud_shader_name = "CloudShader";

@implementation Cloud

-(id)init
{
    self = [super initWithVertex:_cloud_shader_name
                     andFragment:_cloud_shader_name
                     andVarNames:_cloud_names
                     andNumNames:CLD_NUM_NAMES
                     andLastAttr:CLD_LAST_ATTR
                      andHeaders:nil];
    
    return self;
}

-(void)prepareRender:(TG3dObject *)object
{
    [super prepareRender:object];
    GLKMatrix4 pvm = [object calcPVM];
    GLKMatrix4 modelView = object.modelView;
    GLKMatrix3 normalMat = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(pvm), NULL);
    [self writeToLocation:cld_pvm type:TG_MATRIX4 data:pvm.m];
    [self writeToLocation:cld_mvm type:TG_MATRIX4 data:modelView.m];
    [self writeToLocation:cld_normalMat type:TG_MATRIX3 data:normalMat.m];
    float time = (float)object.totalTime;
    [self writeToLocation:cld_time type:TG_FLOAT data:&time];
}

@end
