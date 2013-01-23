//
//  Pool.m
//  TimbreGroove
//
//  Created by victor on 1/19/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Pool.h"
#import "TG3dObject.h"
#import "Generic.h"
#import "Texture.h"

/*
 attribute vec4 position;
 attribute vec3 normal;
 attribute vec2 texture;
 uniform mat4 modelViewProjectionMatrix;
 uniform mat4 modelViewMatrix;
 uniform mat3 normalMatrix;
 uniform highp vec4 materialSpecularColor;
 uniform highp float materialSpecularExponent;
 uniform sampler2D texture0;
 uniform highp vec4 lightPosition; 
 uniform highp float time;

*/

const char * _pool_names[] = {
    "position",
    "normal",
    "texture",
    "modelViewProjectionMatrix",
    "modelViewMatrix",
    "normalMatrix",
    "materialSpecularColor",
    "materialSpecularExponent",
    "texture0",
    "lightPosition",
    "time"
};

const char * _pool_shader_name = "PoolShader";

@implementation Pool

-(id)init
{
    self = [super initWithVertex:_pool_shader_name
                     andFragment:_pool_shader_name
                     andVarNames:_pool_names
                     andNumNames:POOL_NUM_NAMES
                     andLastAttr:POOL_LAST_ATTR
                      andHeaders:nil];
    if( self )
    {
        GLKVector4 spec = { 0.2, 0.2, 0.5, 1.0 };
        [self writeToLocation:pool_specColor type:TG_VECTOR4 data:spec.v];
        float shine = 0.5f;
        [self writeToLocation:pool_shininess type:TG_FLOAT data:&shine];
        self.lightPos =  (GLKVector3){ 0, 0, -3 };
    }
    return self;
}

-(void)setLightPos:(GLKVector3)lightPos
{
    GLKVector4 pos = GLKVector4Make(lightPos.x, lightPos.y, lightPos.z, 0);
    [self writeToLocation:pool_lightPos type:TG_VECTOR4 data:pos.v];
    _lightPos = lightPos;
}

-(void)prepareRender:(TG3dObject *)object
{
    GLKMatrix4 pvm = [object calcPVM];
    GLKMatrix4 modelView = object.modelView;
    GLKMatrix3 normalMat = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(pvm), NULL);
    
    [self writeToLocation:pool_pvm       type:TG_MATRIX4 data:pvm.m];
    [self writeToLocation:pool_mvm       type:TG_MATRIX4 data:modelView.m];
    [self writeToLocation:pool_normalMat type:TG_MATRIX3 data:normalMat.m];
    
}

@end
