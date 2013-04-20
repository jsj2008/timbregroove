//
//  Light.m
//  TimbreGroove
//
//  Created by victor on 1/21/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Light.h"
#import "GenericShader.h"
#import "Generic.h"

@implementation Light

-(id)init
{
    if( (self = [super init]) )
    {
        _desc.position  = (GLKVector4){0, 0, -5, 0 };
        _desc.colors.diffuse = (GLKVector4){ 1, 1, 1, 1 };
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

-(bool)directional
{
    return _desc.position.w == 1.0;
}

-(void)bind:(Shader *)shader object:(Generic *)object
{
    GLKMatrix4 mv = object.modelView;
    GLKMatrix3 normalMat = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(mv), NULL);
    [shader writeToLocation:gv_normalMat type:TG_MATRIX3 data:normalMat.m];
    [shader writeFloats:gv_lights + _lightNumber numFloats:sizeof(_desc)/sizeof(float) data:&_desc];
}

@end

@implementation Lights {
    __weak Generic * _object;
    int _numLights;
}

-(id)initWithObject:(Generic *)object
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
    [shader writeToLocation:gv_lightingEnabled type:TG_INT data:&_numLights];
}
@end
