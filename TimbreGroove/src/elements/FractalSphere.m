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
#import "Mixer.h"
#import "Tweener.h"
#import "Sphere.h"

@interface FractalSphere : Sphere

@end

@interface FractalSphere() {
    Fractal * _texRenderer;
    float _myRot;
    FBO *_fbo;
    Sound * _sound;
    
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

    _sound = [[Mixer sharedInstance] getSound:"TGAmb2-32k"];
    _sound.meteringEnabled = YES;
    _sound.numberOfLoops = -1;
    [_sound play];
    
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
    self.peakVal = 0.2;
}

-(void)setPeakVal:(float)peakVal
{
    _peakVal = peakVal;
    float subColor = TG_CLAMP(peakVal*0.7,0.3,0.6);
    self.light.ambientColor = (GLKVector4){subColor, subColor, peakVal, 1};
}

-(void)tweenDone
{
    _tweening = false;
}
-(void)update:(NSTimeInterval)dt
{
    self.lightRotation += 0.03;
    [super update:dt];

    if( _timer > 1.0/8.0 )
    {
        [_sound updateMeters];
        float peak = [_sound averagePowerForChannel:0];
        if( peak > _pmax )
            _pmax = peak;
        if( peak < _pmin )
            _pmin = peak;
    
//        peak = TG_CLAMP(peak, -160, 0.0);
        float peakVal = ((peak - _pmin) / (_pmax - (_pmin+0.01)));

        if( !_tweening )
        {
            _tweening = true;
            NSDictionary * params = @{
                  TWEEN_DURATION: @(1.0/2.0),
                TWEEN_TRANSITION: TWEEN_FUNC_LINEAR,
                      @"peakVal": @(peakVal),
                TWEEN_ON_COMPLETE_SELECTOR: @"tweenDone",
                TWEEN_ON_COMPLETE_TARGET: self
            };
            
            [Tweener addTween:self withParameters:params];
        }
        
        [_texRenderer update:_timer/2.0];
        [_texRenderer renderToFBO];
        
        _myRot += (peakVal * 5.0);
        float rads = GLKMathDegreesToRadians(_myRot);
        GLKVector3 rot = { GLKMathDegreesToRadians(0), rads, 0};
        self.rotation = rot;
        self.timer = 0.0;
    }
}
@end
