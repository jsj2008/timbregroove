//
//  TestElement.m
//  TimbreGroove
//
//  Created by victor on 1/1/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Fractal.h"
#import "FBO.h"
#import "Light.h"
#import "Sphere.h"
#import "Material.h"

@interface FractalSphere : Sphere

@end

@interface FractalSphere() {
    Fractal * _texRenderer;
    float     _myRot;
    FBO *     _fbo;
    Material  *_mat;
    float     _lightRot;
    Light     *_light;
}
@end

@implementation FractalSphere

-(id)wireUp
{
    _fbo = [[FBO alloc] initWithWidth:128 height:128];
    _texRenderer = [[Fractal alloc] init];
    _texRenderer.fbo = _fbo;
    _texRenderer.backColor = GLKVector4Make(0.3, 0.3, 0.3, 1);
    [_texRenderer wireUp];
    [_texRenderer update:0.01];
    [_texRenderer renderToFBO];

    self.scaleXYZ = 2.0;
    return [super wireUp];
}

-(void)createShader
{
    MaterialColors colors = {
        .ambient  = { 0.8, 0.8, 0.8, 1.0 },
        .diffuse  = { 1.0, 1.0, 1.0, 1.0 },
    };
    
    _mat = [Material withColors:colors shininess:0 doSpecular:false];

    [self addShaderFeature:_mat];
    _light = [Light new];
    [self.lights addLight:_light];
    [self addShaderFeature:_fbo];
    [super createShader];
}

-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];

    // override the default
    putHere[@"Ping!"] = [Parameter withBlock:^(float f) {
        _myRot += f * 30.0;
        self.rotation = (GLKVector3){ 0, GLKMathDegreesToRadians(_myRot), 0 };
        GLKVector4 amb = GLKVector4Normalize((GLKVector4){f, 0, f*0.7, 1.0});
        amb.w = 1.0;
        _mat.ambient = amb;
    }];
    
}
-(void)update:(NSTimeInterval)dt
{
    _lightRot += dt * 35.0;
    _light.rotation = (GLKVector3){ 0, GLKMathDegreesToRadians(_lightRot), 0 };
    [super update:dt];
    [_texRenderer update:dt];
    [_texRenderer renderToFBO];
}

@end
