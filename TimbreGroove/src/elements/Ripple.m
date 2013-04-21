//
//  Ripple.m
//  TimbreGroove
//
//  Created by victor on 2/21/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//


#import "TexturePainter.h"
#import "Shader.h"
#import "GridPlane.h"
#import "Material.h"
#import "Camera.h"
#import "Global.h"
#import "Parameter.h"
#import "Scene.h"
#import "Names.h"
#import "SettingsVC.h"
#import "ShaderTimer.h"

@interface Ripple : TexturePainter
@property (nonatomic,strong) NSString * background;
@end


#define DEFAULT_BACKGROUND @"pool.png"

@implementation Ripple {
    ShaderTimer * _stimer;
}

- (id)init
{
    self = [super initWithFileName:DEFAULT_BACKGROUND];
    if (self) {
        _stimer = [[ShaderTimer alloc] init];
        _stimer.timerType = kSTT_CountDown;
        _stimer.countDownBase = 3.4;
        _timer = _stimer.countDownBase + 0.1;
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
    [shader floatParameter:parameters indexIntoNames:gv_rippleSize value:1.5 range:(FloatRange){1.5,15}];
    [shader pointParameter:parameters indexIntoNames:gv_ripplePt];
    [shader floatParameter:parameters indexIntoNames:gv_time];
 
    self.rotationScale = (GLKVector3){ 0, 0, M_PI_2 };
}

-(void)getShaderFeatureNames:(NSMutableArray *)features
{
    [super getShaderFeatureNames:features];
    [features addObject:kShaderFeatureDistortTexture];
}

-(void)createShader
{
    [self addShaderFeature:_stimer];
    [super createShader];
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
