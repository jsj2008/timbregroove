//
//  Ripple.m
//  TimbreGroove
//
//  Created by victor on 2/21/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//


#import "GenericWithTexture.h"
#import "Shader.h"
#import "GridPlane.h"
#import "Texture.h"
#import "Camera.h"
#import "Global.h"
#import "Parameter.h"
#import "Scene.h"
#import "Names.h"

@interface Ripple : GenericWithTexture {

    ShaderParameterDefinition _ripplePt;
    ShaderParameterDefinition _rippleSize;
    
    float _zRot;
    float _spotRadius;
}
@end


@implementation Ripple

- (id)init
{
    self = [super initWithFileName:@"stars.jpg"];
    if (self) {
        self.timerType = kSTT_CountDown;
        self.countDownBase = 3.4;
        _timer = self.countDownBase + 0.1;
        self.scale = (GLKVector3){ 1.5, 3.0, 0 };
        
        _ripplePt = (ShaderParameterDefinition){
            { TG_POINT, {{ 0.0, 0.0 }}, {{ -1.0,-1.0 }}, {{ 1.0,1.0 }}, kTweenEaseOutSine, 1.0  },
            gv_ripplePt
        };
        
        _rippleSize = (ShaderParameterDefinition){
            { TG_FLOAT, { 1.5 }, { 1.5 }, { 15.0 }, kTweenLinear, 0.0, kParamFlagPerformScaling },
            gv_rippleSize
        };
        
    }
    return self;
}

-(void)installParameters
{
    [_parameters addObject:[[ShaderParameter alloc] initWithShaderDef:&_rippleSize]];
    [_parameters addObject:[[ShaderParameter alloc] initWithShaderDef:&_ripplePt]];
}


-(id)wireUp
{
    [super wireUp];

    Scene * scene = [Global sharedInstance].scene;
    [scene setParameter:kParamChannelVolume value:1.0 func:kTweenLinear duration:0.0];
    
    NSTimeInterval initTime = self.countDownBase;
    [self.shader writeToLocation:gv_time type:TG_FLOAT data:&initTime];
    return self;
}


-(void)update:(NSTimeInterval)dt
{
    [super update:dt];
    _zRot += 0.04;
    self.rotation = (GLKVector3){ 0, 0, GLKMathDegreesToRadians(_zRot) };
}

-(void)getShaderFeatures:(NSMutableArray *)putHere
{
    [super getShaderFeatures:putHere];
    [putHere addObject:kShaderFeatureDistortTexture];
}

@end
