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

#define TLOG_POS { GLKVector4 v4 = [self positionLight]; TGLog(LLLights, @"Light position: { %f, %f, %f } (%f)", v4.x, v4.y, v4.z, v4.w); }

@implementation Light
-(id)init
{
    if( (self = [super init]) )
    {
        _desc.position  = (GLKVector4){0, 0, 5, 0 };
        _desc.colors.diffuse = (GLKVector4){ 0.8, 0.8, 0.8, 1};
        _desc.colors.ambient = (GLKVector4){ 0.5, 0.5, 0.5, 1};
        _desc.attenuation = (GLKVector3){1, 0, 0};
        _desc.spotDirection = (GLKVector3){ 0, 0, 1 };
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
    TLOG_POS;
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

-(GLKVector3)spotDirection
{
    return _desc.spotDirection;
}

-(void)setSpotDirection:(GLKVector3)spotDirection
{
    _desc.spotDirection = GLKVector3Normalize(spotDirection);
}

-(GLKVector4)positionLight
{
    GLKMatrix4 mx = GLKMatrix4Identity;
    if( _rotation.x )
        mx = GLKMatrix4Rotate(mx, _rotation.x, 1.0f, 0.0f, 0.0f);
    if( _rotation.y )
        mx = GLKMatrix4Rotate(mx, _rotation.y, 0.0f, 1.0f, 0.0f);
    if( _rotation.z )
        mx = GLKMatrix4Rotate(mx, _rotation.z, 0.0f, 0.0f, 1.0f);
    
    GLKVector3 vec3 = GLKMatrix4MultiplyVector3WithTranslation(mx, *(GLKVector3 *)&_desc.position);
    
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
    
    if( _desc.spotCutoffAngle )
    {
        [shader writeToLocation:gv_lights0_spotCutoffAngle     + offset type:TG_FLOAT   data:&_desc.spotCutoffAngle];
        [shader writeToLocation:gv_lights0_spotDirection       + offset type:TG_VECTOR3 data:&_desc.spotDirection];
        [shader writeToLocation:gv_lights0_spotFalloffExponent + offset type:TG_FLOAT   data:&_desc.spotFalloffExponent];
    }
}

-(void)unbind:(Shader *)shader {}

#define RAD_TURNS(f) (f * (M_PI / 180))
#define POS_MASSAGE(f) (f * 0.6)

-(void)getParameters:(NSMutableDictionary *)parameters
{
    parameters[kParamLightReset] = [Parameter withBlock:^(CGPoint pt) {
        self.position = (GLKVector3){ 0, 0, 8 };
        self.rotation = (GLKVector3){ 0, 0, 0 };
        self.attenuation = (GLKVector3){ 0, 0.002, 0 };
        self.spotDirection = (GLKVector3){ 0, 0, -1 };
        _desc.spotCutoffAngle = 0.0;
        _desc.spotFalloffExponent = 0.0;
        TLOG_POS;
    }];
    
    parameters[kParamLightRotationX] = [Parameter withBlock:^(float f) {
        GLKVector3 r = self.rotation;
        r.x += RAD_TURNS(f * 3);
        self.rotation = r;
        TLOG_POS;
    }];
    parameters[kParamLightRotationY] = [Parameter withBlock:^(float f) {
        GLKVector3 r = self.rotation;
        r.y += RAD_TURNS(f * 3);
        self.rotation = r;
        TLOG_POS;
    }];
    parameters[kParamLightRotationZ] = [Parameter withBlock:^(float f) {
        GLKVector3 r = self.rotation;
        r.z += RAD_TURNS(f * 3);
        self.rotation = r;
        TLOG_POS;
    }];
    
    parameters[ kParamLightX ] = [FloatParameter withBlock:^(float x) {
        _desc.position.x += POS_MASSAGE(-x);
        TLOG_POS;
    }];
    parameters[ kParamLightY ] = [FloatParameter withBlock:^(float y) {
        _desc.position.y += POS_MASSAGE(y);
        TLOG_POS;
    }];
    parameters[ kParamLightZ ] = [FloatParameter withBlock:^(float z) {
        _desc.position.z += POS_MASSAGE(z);
        TLOG_POS;
    }];
    parameters[ kParamLightIntensity ] = [FloatParameter withBlock:^(float value) {
        _desc.attenuation.y  = value * 0.2;
        TGLog(LLLights, @"Light attenuation: constant: %f linear: %f  quad: %f",
              _desc.attenuation.x, _desc.attenuation.y, _desc.attenuation.z);
    }];
    parameters[ kParamLightWidth ] = [FloatParameter withBlock:^(float value) {
        _desc.spotCutoffAngle  += value * 5.0;
        TGLog(LLLights, @"Light spot angle: %f", _desc.spotCutoffAngle);
    }];
    parameters[ kParamLightDropoff ] = [FloatParameter withBlock:^(float value) {
        _desc.spotFalloffExponent += value;
        TGLog(LLLights, @"Light FalloffExponent: %f (%f)", _desc.spotFalloffExponent, value );
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
