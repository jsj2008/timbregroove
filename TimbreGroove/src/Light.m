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

@implementation Light

-(id)init
{
    if( (self = [super init]) )
    {
        _desc.position  = (GLKVector4){0, 0, -5, 0 };
        _desc.colors.diffuse = (GLKVector4){ 1, 1, 1, 1 };
        _desc.colors.ambient = (GLKVector4){ 1, 1, 1, 1 };
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

-(void)setDirectional:(bool)directional
{
    _desc.position.w = directional ? 1.0 : 0.0;
}

-(void)setAttenuation:(GLKVector3)attenuation
{
    _desc.attenuation = attenuation;
}

-(GLKVector3)attenuation
{
    return _desc.attenuation;
}

-(bool)directional
{
    return _desc.position.w == 1.0;
}

-(void)bind:(Shader *)shader object:(Painter *)object
{
    GLKMatrix4 mv = object.modelView;
    GLKMatrix3 normalMat = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(mv), NULL);
    [shader writeToLocation:gv_normalMat type:TG_MATRIX3 data:normalMat.m];
    int offset = LIGHT_STRUCT_NUM_ELEMENTS * _lightNumber;
    //[shader writeFloats:gv_lights0_colors + offset numFloats:sizeof(_desc.colors)/sizeof(float) data:&_desc.colors];
    
    GLint lightLoc = [shader location:gv_lights0_colors + offset];
    glUniform4fv(lightLoc, 4, (GLfloat *)&_desc.colors.ambient );
    
    [shader writeToLocation:gv_lights0_position    + offset type:TG_VECTOR4 data:&_desc.position];
    [shader writeToLocation:gv_lights0_attenuation + offset type:TG_VECTOR3 data:&_desc.attenuation];
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
@end
