//
//  Light.m
//  TimbreGroove
//
//  Created by victor on 1/21/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Light.h"
#import "GenericShader.h"
#import "Painter.h"
#import "Parameter.h"
#import "Names.h"

@implementation Light

-(id)init
{
    if( (self = [super init]) )
    {
        _desc.position  = (GLKVector4){0, 0, -5, 0 };
        _desc.colors.diffuse = (GLKVector4){ 0.2, 0.2, 0.2, 0.2 };
        _desc.colors.ambient = (GLKVector4){ 0.2, 0.2, 0.2, 0.2 };
        _desc.attenuation = (GLKVector3){1, 1, 1};
    }
    
    return self;
}

-(GLKVector3)position
{
    return (GLKVector3){ _desc.position.x, _desc.position.y, _desc.position.z };
}

-(void)setPosition:(GLKVector3)position
{
    _desc.position = (GLKVector4){ position.x, position.y, position.z, _desc.position.w };
}

-(void)setPoint:(bool)point
{
    _desc.position.w = point ? 1.0 : 0.0;
}

-(bool)point
{
    return _desc.position.w == 1.0;
}

-(void)setAttenuation:(GLKVector3)attenuation
{
    _desc.attenuation = attenuation;
}

-(GLKVector3)attenuation
{
    return _desc.attenuation;
}

-(GLKVector4)ambient
{
    return _desc.colors.ambient;
}

-(void)setAmbient:(GLKVector4)ambient
{
    _desc.colors.ambient = ambient;
}

-(GLKVector4)diffuse
{
    return _desc.colors.diffuse;
}

-(void)setDiffuse:(GLKVector4)diffuse
{
    _desc.colors.diffuse = diffuse;
}

-(GLKVector4)positionLight
{
    GLKMatrix3 mx = GLKMatrix3Identity;//  GLKMatrix4MakeTranslation( _desc.position.x, _desc.position.y, _desc.position.z );
    
    if( _rotation.x )
        mx = GLKMatrix3Rotate(mx, _rotation.x, 1.0f, 0.0f, 0.0f);
    if( _rotation.y )
        mx = GLKMatrix3Rotate(mx, _rotation.y, 0.0f, 1.0f, 0.0f);
    if( _rotation.z )
        mx = GLKMatrix3Rotate(mx, _rotation.z, 0.0f, 0.0f, 1.0f);
    
    GLKVector3 vec3 = GLKMatrix3MultiplyVector3(mx, *(GLKVector3 *)&_desc.position);
    
    return (GLKVector4){ vec3.x, vec3.y, vec3.z, _desc.position.w };
    
}

-(void)bind:(Shader *)shader object:(Painter *)object
{
    GLKMatrix4 mv = object.modelView;
    GLKMatrix3 normalMat = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(mv), NULL);
    [shader writeToLocation:gv_normalMat type:TG_MATRIX3 data:normalMat.m];
    
    int offset = LIGHT_STRUCT_NUM_ELEMENTS * _lightNumber;
    
    GLKVector4 vec4 = [self positionLight];
    [shader writeToLocation:gv_lights0_position    + offset type:TG_VECTOR4 data:&vec4];
    [shader writeToLocation:gv_lights0_attenuation + offset type:TG_VECTOR3 data:&_desc.attenuation];
    [shader writeToLocation:gv_lights0_colors      + offset type:TG_VECTOR4 data:&_desc.colors count:4];
}

-(void)unbind:(Shader *)shader {}

#define POS_MASSAGE(f) (f * 0.6)

-(void)getParameters:(NSMutableDictionary *)putHere
{
    putHere[ kParamLightX ] = [FloatParameter withBlock:^(float x) {
        TGLog(LLGestureStuff, @"Got light pan: %f",x);
        _desc.position.x += POS_MASSAGE(-x);
    }];
    putHere[ kParamLightY ] = [FloatParameter withBlock:^(float y) {
        _desc.position.y += POS_MASSAGE(y);
    }];
    putHere[ kParamLightZ ] = [FloatParameter withBlock:^(float z) {
        _desc.position.z += POS_MASSAGE(z);
    }];
    putHere[ kParamLightIntensity ] = [FloatParameter withBlock:^(float value) {
        _desc.attenuation.x  = value;
    }];
}

@end

@implementation Lights {
    __weak Painter * _object;
    int _numLights;
}

-(id)initWithObject:(Painter *)object
{
    self = [super init];
    if( self )
    {
        _object = object;
    }
    return self;
}

-(void)addLight:(Light *)light
{
    ++_numLights;
    [_object addShaderFeature:light];
}

-(void)bind:(Shader *)shader object:(id)object
{
    [shader writeToLocation:gv_lightsEnabled type:TG_INT data:&_numLights];
}

-(void)unbind:(Shader *)shader {}

@end
