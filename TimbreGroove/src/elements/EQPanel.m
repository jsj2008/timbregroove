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
#import "FivePointBezier.h"
#import "Global.h"
#import "GraphView.h"

@interface EQPanel () {
    GLKVector3  *_parametric;
    GLKVector3  *_lowPassRes;
    GLKVector3  *_hiPassRes;
}

@end
@implementation EQPanel

-(id)wireUp
{
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
    
    self.shapeDisplay = kBezShape_HiPassRes;
    self.shapeEdit = kBezShape_HiPassRes;

    return self;
}

-(void)didAttachToView:(GraphView *)view
{
    [view watchForGlobals:self lookup:@{@"panXBy":@"panChanged",
                                        @"panYBy":@"panChanged"}];
}

-(void)panChanged
{
    Global * global = [Global sharedInstance];
    FivePointBezier * fpb = (FivePointBezier *)self.shader;
    CGPoint left = fpb.left;
    CGPoint right = fpb.right;
    CGPoint hiPoint = fpb.hiPoint;
    if( _shapeEdit == kBezShape_Parametric )
    {
        float xmove = global.panXBy / 2.0;
        left.x += xmove;
        right.x -= xmove;
    }
    else
    {
        CGPoint rCntrl = fpb.rightController;
        CGPoint lCntrl = fpb.leftController;
        float xmove = global.panXBy;
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
        fpb.rightController = rCntrl;
        fpb.leftController = lCntrl;
    }
    hiPoint.y += global.panYBy;
    
    fpb.hiPoint = hiPoint;
    fpb.left = left;
    fpb.right = right;
}

-(void)setShapeDisplay:(BezShapes)shapeDisplay
{
    FivePointBezier * fpb = (FivePointBezier *)self.shader;
    
    if( shapeDisplay == kBezShape_Parametric )
        fpb.controlPoints = _parametric;
    else if( shapeDisplay == kBezShape_LowPassRes )
        fpb.controlPoints = _lowPassRes;
    else
        fpb.controlPoints = _hiPassRes;
    
    _shapeDisplay = shapeDisplay;
}

-(void)createShader
{
    self.shader = [FivePointBezier new];
}

-(void)createBuffer
{
    [self addBuffer:[[SixPointBezierMesh alloc] init]];
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    [super render:w h:h];
    /*
     eqBands bands[2] = { kEQLow, kEQHigh };
     GLKVector4 colors[2] = {
     { 0.5, 0.8, 1, 1 },
     { 0.5, 1, 0.5, 1 }
     };
     Mixer * mixer = [Mixer sharedInstance];
     
     for( int i = 0; i < 2; i++ )
     {
     self.color = colors[i];
     mixer.selectedEQBand = bands[i];
     AudioUnitParameterValue peak   = mixer.eqPeak + 0.5;
     AudioUnitParameterValue center = mixer.eqCenter;
     AudioUnitParameterValue bwidth = mixer.eqBandwidth + 0.5;
     [self setCurveHeight:peak width:bwidth offset:center*2.0 - 0.5];
     [super render:w h:h];
     }
     */
}

@end

