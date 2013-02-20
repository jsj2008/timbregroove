//
//  EQPanel.m
//  TimbreGroove
//
//  Created by victor on 2/14/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "EQPanel.h"
#import "Mixer.h"
#import "Mixer+Parameters.h"
#import "Global.h"
#import "GraphView.h"
#import "FBO.h"
#import "Texture.h"
#import "GenericWithTexture.h"

@interface EQOffText : GenericWithTexture
@end
@implementation EQOffText
-(void)createTexture
{
    self.texture = [[Texture alloc] initWithString:@"EQ Off"];
}
@end

//#define TEST_WITH_SQUARE

#ifdef TEST_WITH_SQUARE
#import "GridPlane.h"
#else
#import "FivePointBezier.h"
#endif

@interface EQPanel () {
    GLKVector3  *_parametric;
    GLKVector3  *_lowPassRes;
    GLKVector3  *_hiPassRes;
    bool _IamATexture;
    
    EQOffText * _eqOff;
}

@end
@implementation EQPanel

-(id)wireUp
{
    [super wireUp];
    
#ifndef TEST_WITH_SQUARE
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
    
    self.shapeDisplay = kBezShape_LowPassRes;
    self.shapeEdit = kBezShape_LowPassRes;
#endif
    
    _IamATexture = self.fbo != nil;
    
    if( _IamATexture )
    {
        self.fbo.allowDepthCheck = true;
        self.fbo.clearColor = (GLKVector4){0.3, 0.3, 0.7, 1.0};
        self.scale = (GLKVector3){ 0.25, 1, 1 };
        
        _eqOff = [[EQOffText new] wireUp]; // [[[Text alloc] initWithString:@"EQ off"] wireUp];
        _eqOff.position = (GLKVector3){0.75, 0, 0 };
        _eqOff.scale =self.scale;
        //_eqOff.scale = self.scale;
        [self appendChild:_eqOff];
    }
    return self;
}

-(void)didAttachToView:(GraphView *)view
{
    [view watchForGlobals:@{  kParamKnob1:^{ [self updateCurve:0]; },
                              kParamKnob2:^{ [self updateCurve:1]; },
                              kParamKnob3:^{ [self updateCurve:2]; }}];
    
    if( _eqOff )
       [_eqOff didAttachToView:view];
}

-(void)toggleBand
{
    CGPoint pt = [Global sharedInstance].paramPad1;
    eqBands band;
    if( pt.y <= 0.333)
        band = kEQLow;
    else if( pt.y >= 0.666)
        band = kEQHigh;
    else
        band = kEQMid;

    [Mixer sharedInstance].selectedEQBand = band;
    self.shapeDisplay = band;
    self.shapeEdit = band;
}

-(void)updateCurve:(int)knobNum
{
#ifndef TEST_WITH_SQUARE
    if(knobNum == 2 && _shapeEdit != kBezShape_Parametric)
        return;
    
    self.shapeDisplay = _shapeEdit;
    
    FivePointBezier *  fpb    = (FivePointBezier *)self.shader;
    Global *           global = [Global sharedInstance];

    CGPoint left    = fpb.left;
    CGPoint right   = fpb.right;
    CGPoint rCntrl  = fpb.rightController;
    CGPoint lCntrl  = fpb.leftController;
    CGPoint hiPoint = fpb.hiPoint;
 
    if( knobNum == 2 )
    {
        float xmove2 = global.paramKnob3;
        left.x -= xmove2;
        right.x += xmove2;
    }
    else
    {
        float xmove = global.paramKnob1;
        float ymove = global.paramKnob2;
        
        rCntrl.x += xmove;
        lCntrl.x += xmove;
        hiPoint.x += xmove;
        if( _shapeEdit == kBezShape_LowPassRes )
        {
            right.x += xmove;
        }
        else if( _shapeEdit == kBezShape_HiPassRes )
        {
            left.x += xmove;
        }
        
        hiPoint.y += ymove;
    }
    

    fpb.left              = left;
    fpb.right             = right;
    fpb.rightController   = rCntrl;
    fpb.leftController    = lCntrl;
    fpb.hiPoint           = hiPoint;
#endif
}

-(void)setShapeDisplay:(BezShapes)shapeDisplay
{
#ifndef TEST_WITH_SQUARE
    FivePointBezier * fpb = (FivePointBezier *)self.shader;

    if( shapeDisplay == kBezShape_Parametric )
        fpb.controlPoints = _parametric;
    else if( shapeDisplay == kBezShape_LowPassRes )
        fpb.controlPoints = _lowPassRes;
    else
        fpb.controlPoints = _hiPassRes;
    
    _shapeDisplay = shapeDisplay;
#endif
}

#ifndef TEST_WITH_SQUARE
-(void)createShader
{
    self.shader = [FivePointBezier new];
}

-(void)setColor:(GLKVector4)color
{
    FivePointBezier * fpb = (FivePointBezier *)self.shader;
    fpb.color = color;
}
#endif

-(void)createBuffer
{
#ifdef TEST_WITH_SQUARE
    MeshBuffer * mb = [GridPlane gridWithWidth:0.5 andGrids:1 andIndicesIntoNames:@[@(gv_pos)]
                                      andDoUVs:false andDoNormals:false];
    [self addBuffer:mb];
#else
    [self addBuffer:[[FivePointBezierMesh alloc] init]];
#endif
}

-(void)update:(NSTimeInterval)dt mixerUpdate:(MixerUpdate *)mixerUpdate
{
    [super update:dt mixerUpdate:mixerUpdate];
    if( _eqOff )
       [_eqOff update:dt mixerUpdate:mixerUpdate];
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    if( _IamATexture )
    {
        GLKVector3 pos = (GLKVector3){ -0.75, -0.5, -0.1 };
        self.shapeDisplay = kBezShape_LowPassRes;
        self.color = (GLKVector4){1,0.5,0.5,1};
        self.position = pos;
        [super render:w h:h];
        self.shapeDisplay = kBezShape_Parametric;
        self.color = (GLKVector4){1,1,0,1};
        pos.x = -0.25;
        self.position = pos;
        [super render:w h:h];
        self.shapeDisplay = kBezShape_HiPassRes;
        self.color = (GLKVector4){0.5,1,1,1};
        pos.x = 0.25;
        self.position = pos;
        [super render:w h:h];
        
#ifdef TEST_WITH_SQUARE
        self.color = (GLKVector4){1,1,0.5,1};
        pos.x = 0.75;
        self.position = pos;
        [super render:w h:h];
#else
        if( _eqOff )
           [_eqOff render:w h:h];
#endif

    }
    else
    {
        [super render:w h:h];
    }
}

@end

