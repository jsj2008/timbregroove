//
//  EQPanel.m
//  TimbreGroove
//
//  Created by victor on 2/14/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//
#define NO_EQPANEL_DECLS


#import "EQPanel.h"

#import "Global.h"
#import "Scene.h"
#import "Parameter.h"
#import "Names.h"

#import "GraphView.h"
#import "FBO.h"
#import "Texture.h"
#import "GenericWithTexture.h"

#import "Scene.h"
#import "Audio.h"
#import "SoundSystemParameters.h"

NSString const * kParamCurveCutoff   = @"CurveCutoff";
NSString const * kParamCurveWidth   = @"CurveWidth";

@interface EQOffText : GenericWithTexture
@end
@implementation EQOffText
-(void)createTexture
{
    self.texture = [[Texture alloc] initWithString:@"EQ Off"];
}
@end

#import "FivePointBezier.h"

@interface EQPanel () {
    GLKVector3  *_parametric;
    GLKVector3  *_lowPassRes;
    GLKVector3  *_hiPassRes;
    bool _IamATexture;
    EQOffText * _eqOff;
    
    FloatParamBlock _eqLowFreq;
    FloatParamBlock _eqHighFreq;
    FloatParamBlock _eqMidWidth;
}
@end

@implementation EQPanel

-(id)wireUp
{
    self.disableStandarParameters = true;
    
    [super wireUp];
    
    static GLKVector3 parametric[5] = {
         { -1.00,  0.00, 0 },
         { -0.30,  0.50, 0 },
         {  0.00,  2.00, 0 },
         {  0.30,  0.50, 0 },
         {  1.00,  0.00, 0 }
    };
    static GLKVector3 lowpass[5] = {
         { -1.00,  1.00, 0 },
         { -0.05,  1.00, 0 },
         {  0.00,  1.00, 0 },
         {  0.00,  0.50, 0 },
         {  0.00,  0.00, 0 }
    };
    static GLKVector3 hipass[5] = {
         {  0.00,  0.00, 0 },
         {  0.00,  0.50, 0 },
         {  0.00,  1.00, 0 },
         {  0.05,  1.00, 0 },
         {  1.00,  1.00, 0 }
    };
    
    _parametric = parametric;
    _lowPassRes = lowpass;
    _hiPassRes  = hipass;
    
    _IamATexture = self.fbo != nil;
    
    if( _IamATexture )
    {
        self.fbo.allowDepthCheck = true;
        self.fbo.clearColor = (GLKVector4){0.3, 0.3, 0.3, 1.0};
        self.scale = (GLKVector3){ 0.25, 1, 1 };
        
        _eqOff = [[EQOffText new] wireUp]; 
        _eqOff.position = (GLKVector3){0.75, 0, 0 };
        _eqOff.scale = self.scale;
        [self appendChild:_eqOff];
    }
    return self;
}

-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];

    putHere[kParamCurveCutoff] = [Parameter withBlock:^(float x) {
        if( _band == eqbLow || _band == eqbHigh )
            [self moveCutoff:x band:_band sendParam:true];
    }];
    
    putHere[kParamCurveWidth] = [Parameter withBlock:^(float f) {
        if( _band == eqbMid )
            [self updateCurve:f];
    }];
}

-(void)triggersChanged:(Scene *)scene
{
    [super triggersChanged:scene];
    
    if( scene )
    {
        TriggerMap * tm = scene.triggers;

        _eqLowFreq  = [tm getFloatTrigger:[kParamEQLowCutoff    stringByAppendingTween:kTweenEaseInSine len:0.2]];
        _eqHighFreq = [tm getFloatTrigger:[kParamEQHighCutoff   stringByAppendingTween:kTweenEaseInSine len:0.2]];
        _eqMidWidth = [tm getFloatTrigger:[kParamEQMidBandwidth stringByAppendingTween:kTweenEaseInSine len:0.2]];
        
        SoundSystemParameters * ssp = scene.audio.ssp;
        [self moveCutoff:[ssp getCurrentEQValue:kEQKnobFreq band:0] band:eqbLow  sendParam:false];
        [self moveCutoff:[ssp getCurrentEQValue:kEQKnobFreq band:2] band:eqbHigh sendParam:false];
    }
    else
    {
        _eqLowFreq = nil;
        _eqHighFreq = nil;
        _eqMidWidth = nil;
    }
}

-(void)moveCutoff:(float)xpos band:(int)band sendParam:(bool)sendParam
{
    GLKVector3 * pts = NULL;
    if( band == eqbLow )
        pts = _lowPassRes;
    else if( band == eqbHigh )
        pts = _hiPassRes;
    
    int index = 0;

    if( band == eqbLow )
    {
        index = BEZ_RIGHT_PT;
        if( sendParam )
            _eqLowFreq(xpos);
    }
    else if( band == eqbHigh )
    {
        index = BEZ_LEFT_PT;
        if( sendParam )
            _eqHighFreq(xpos);
    }
    
    float oldVal = pts[index].x;
    float newVal = /*pts[index].x + */ xpos;
    
#define MAX_X_DIM 0.95
    
    if( newVal <= -MAX_X_DIM )
        newVal = -MAX_X_DIM;
    else if( newVal > MAX_X_DIM )
        newVal = MAX_X_DIM;

    float diff = newVal - oldVal;
    pts[index].x = newVal;
    pts[BEZ_RIGHT_CTRL_PT].x += diff;
    pts[BEZ_LEFT_CTRL_PT].x  += diff;
    pts[BEZ_HI_PT].x         += diff;

    
}

-(void)updateCurve:(float)scale
{
    _parametric[BEZ_LEFT_PT].x  -= scale;
    _parametric[BEZ_RIGHT_PT].x += scale;
    _eqMidWidth(scale);
}

-(void)createShader
{
    self.shader = [FivePointBezier new];
}

-(void)createBuffer
{
    [self addBuffer:[[FivePointBezierMesh alloc] init]];
}

-(void)update:(NSTimeInterval)dt
{
    [super update:dt];
    if( _eqOff )
       [_eqOff update:dt];
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    if( _IamATexture )
    {
        FivePointBezier * fpb = (FivePointBezier *)self.shader;        
        GLKVector3 pos = (GLKVector3){ -0.75, -0.5, -0.1 };
        fpb.controlPoints = _lowPassRes;
        fpb.color = (GLKVector4){1,0.5,0.5,1};
        self.position = pos;
        [super render:w h:h];
        fpb.controlPoints = _parametric;
        fpb.color = (GLKVector4){1,1,0,1};
        pos.x = -0.25;
        self.position = pos;
        [super render:w h:h];
        fpb.controlPoints = _hiPassRes;
        fpb.color = (GLKVector4){0.5,1,1,1};
        pos.x = 0.25;
        self.position = pos;
        [super render:w h:h];
        
        if( _eqOff )
           [_eqOff render:w h:h];
    }
    else
    {
        [super render:w h:h];
    }
}

@end

