//
//  TestElement.m
//  TimbreGroove
//
//  Created by victor on 1/1/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "FractalSphere.h"
#import "Fractal.h"
#import "FBO.h"

@interface FractalSphere() {
    Fractal * _texRenderer;
    float _myRot;
    FBO *_fbo;
}
@end

@implementation FractalSphere

-(id)wireUp
{
    _fbo = [[FBO alloc] initWithWidth:256 height:256];
    _texRenderer = [[Fractal alloc] init];
    _texRenderer.fbo = _fbo;
    _texRenderer.backColor = GLKVector4Make(0.3, 0.3, 0.6, 1);
    [_texRenderer wireUp];
    self.ambient = GLKVector3Make(0, 0.5, 1);
    return [super wireUp];
}

-(void)createTexture
{
    self.texture = _fbo;
}

-(void)update:(NSTimeInterval)dt
{
    [_texRenderer update:dt];
    [_texRenderer renderToFBO];
    [super update:dt];
    _myRot += 0.7;
    float rads = GLKMathDegreesToRadians(_myRot);
    GLKVector3 rot = { GLKMathDegreesToRadians(38), rads, 0};
    self.rotation = rot;
}
@end
