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
#import "SettingsVC.h"

@interface Ripple : GenericWithTexture {
    float _zRot;
    float _spotRadius;
}
@property (nonatomic,strong) NSString * background;
@end


#define DEFAULT_BACKGROUND @"aotk-ass-outline-512.tif"

@implementation Ripple

- (id)init
{
    self = [super initWithFileName:DEFAULT_BACKGROUND];
    if (self) {
        self.timerType = kSTT_CountDown;
        self.countDownBase = 3.4;
        _timer = self.countDownBase + 0.1;
        self.scale = (GLKVector3){ 1.5, 3.0, 0 };
        _background = DEFAULT_BACKGROUND;
    }
    return self;
}

-(void)setBackground:(NSString *)background
{
    self.texture = [[Texture alloc] initWithFileName:background];
    _background = background;
}

-(void)getParameters:(NSMutableDictionary *)parameters
{
    [super getParameters:parameters];
    
    Shader * shader = self.shader;
    [shader floatParameter:parameters idx:gv_rippleSize value:1.5 range:(FloatRange){1.5,15}];
    [shader pointParameter:parameters idx:gv_ripplePt];
    [shader floatParameter:parameters idx:gv_time];
    
    parameters[@"zRotation"] = [Parameter withBlock:^(float f) {
        _zRot += 0.04;
        self.rotation = (GLKVector3){ 0, 0, GLKMathDegreesToRadians(_zRot) };
    }];
}


-(id)wireUp
{
    [super wireUp];
    
    NSTimeInterval initTime = self.countDownBase;
    [self.shader writeToLocation:gv_time type:TG_FLOAT data:&initTime];
    return self;
}


-(void)update:(NSTimeInterval)dt
{
    [super update:dt];
}

-(void)getShaderFeatures:(NSMutableArray *)features
{
    [super getShaderFeatures:features];
    
    [features addObject:kShaderFeatureDistortTexture];
    [features addObject:kShaderFeatureTime];
}

- (void)getSettings:(NSMutableArray *)arr
{
    [super getSettings:arr];
    
    NSDictionary * images = @{ @"stars.jpg"   : @"Star field",
                               @"pool.png"    : @"Pool",
                               @"gridtest.png": @"Grid",
                               @"aotk-ass-outline-512.tif" : @"Logo"
                               };
    
    NSDictionary * options = @{@"values" : images,
                               @"target" : self,
                               @"key"    : @"background"};

    SettingsDescriptor * sd;
    sd = [[SettingsDescriptor alloc]  initWithControlType: SC_Picker
                                               memberName: @"background"
                                                labelText: @"Background"
                                                  options: options
                                             initialValue: _background
                                                 priority: SHADER_SETTINGS];
    
    [arr addObject:sd];    
}

@end
