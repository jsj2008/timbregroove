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

@interface FractalSphere : Sphere

@end

@interface FractalSphere() {
    Fractal * _texRenderer;
    float _myRot;
    FBO *_fbo;
    
    float _pmin;
    float _pmax;
    bool _tweening;
}
@property (nonatomic) float peakVal;
@end

@implementation FractalSphere

-(id)wireUp
{
    _fbo = [[FBO alloc] initWithWidth:512 height:512];
    _texRenderer = [[Fractal alloc] init];
    _texRenderer.fbo = _fbo;
    _texRenderer.backColor = GLKVector4Make(0.3, 0.3, 0.3, 1);
    [_texRenderer wireUp];
    [_texRenderer update:0.01];
    [_texRenderer renderToFBO];

    _pmin = 1000.0;
    _pmax = -200.0;
    
    return [super wireUp];
}

-(void)createTexture
{
    self.texture = _fbo;
}

-(void)configureLighting
{
    if( !self.light )
        self.light = [Light new]; // defaults are good
    float subColor = 0;
    self.light.ambientColor = (GLKVector4){subColor, subColor, 1.0, 1.0};
    
    GLKVector3 lDir = self.light.direction;
    GLKMatrix4 mx = GLKMatrix4MakeTranslation( lDir.x, lDir.y, lDir.z );
    self.light.direction = GLKMatrix4MultiplyVector3(mx,(GLKVector3){-1, 0, -1});
}

-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];

    // override the default
    putHere[@"Ping!"] = [Parameter withBlock:^(float f) {
        _myRot += f * 45.0;
        self.rotation = (GLKVector3){ 0, GLKMathDegreesToRadians(_myRot), 0 };
        self.light.ambientColor = (GLKVector4){f, f*0.7, f, 1.0};
    }];
    
}
-(void)update:(NSTimeInterval)dt
{
   // self.lightRotation += 0.03;
    [super update:dt];
    [_texRenderer update:dt];
    [_texRenderer renderToFBO];
}

/*
    if( self.timer > 1.0/8.0 )
    {
        
        _myRot += 0.4; // (peakVal * 5.0);
        float rads = GLKMathDegreesToRadians(_myRot);
        GLKVector3 rot = { GLKMathDegreesToRadians(0), rads, 0};
        self.rotation = rot;
        self.timer = 0.0;
    }
}
 */
@end
