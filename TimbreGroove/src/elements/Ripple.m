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


#define DEFAULT_BACKGROUND @"stars.jpg"

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

-(void)getParameters:(NSMutableDictionary *)putHere
{
    Shader * shader = self.shader;
    [shader floatParameter:putHere idx:gv_rippleSize value:1.5 range:(FloatRange){1.5,15}];
    [shader pointParameter:putHere idx:gv_ripplePt];
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
    _zRot += 0.04;
    self.rotation = (GLKVector3){ 0, 0, GLKMathDegreesToRadians(_zRot) };
}

-(void)getShaderFeatures:(NSMutableArray *)putHere
{
    [super getShaderFeatures:putHere];
    [putHere addObject:kShaderFeatureDistortTexture];
}

- (void)getSettings:(NSMutableArray *)arr
{
    NSDictionary * images = @{ @"stars.jpg": @"Star field",
                                @"pool.png": @"Pool",
                               @"gridtest.png": @"Grid" };
    
    SettingsDescriptor * sd;
    sd = [[SettingsDescriptor alloc]  initWithControlType: SC_Picker
                                               memberName: @"background"
                                                labelText: @"Background"
                                                  options: @{@"values":images,
          @"target":self, @"key":@"background"}
                                             initialValue: _background
                                                 priority: SHADER_SETTINGS];
    
    [arr addObject:sd];    
}

@end
