//
//  SpinCube.m
//  TimbreGroove
//
//  Created by victor on 2/17/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "SpinCube.h"
#import "Cube.h"
#import "EQPanel.h"
#import "FBO.h"
#import "Light.h"
#import "GraphView.h"
#import "Mixer.h"
#import "Tweener.h"
#import "Global.h"
#import "GenericWithTexture.h"
#import "EventCapture.h"

#define CUBE_TILT  -0.2
#define CUBE_WIDTH 1.8
#define BUTTON_SCALE 0.25

@interface SpinCube () {
    EQPanel * _eqPanel;
    FBO * _fbo;
    GenericWithTexture * _next;
    GenericWithTexture * _prev;
    
    unsigned int _currentFace;
}
@property (nonatomic) float cubeRotation;
@end
@implementation SpinCube

-(id)wireUp
{
    _fbo = [[FBO alloc] initWithWidth:1024 height:256];
    _eqPanel = [[EQPanel alloc] init];
    _eqPanel.fbo = _fbo;
    [_eqPanel wireUp];
    
    [super wireUp];

    self.rotation = (GLKVector3){ CUBE_TILT,  0, 0 };

    _next = [[GenericWithTexture alloc] initWithText:@"Next -->"];
    _prev = [[GenericWithTexture alloc] initWithText:@"<-- Prev"];
    
    _next.scaleXYZ = BUTTON_SCALE;
    _next.interactive = true;
    _next.color = (GLKVector4){ 0.5, 0.0, 0.0, 1.0 };
    _prev.scaleXYZ = BUTTON_SCALE;
    _prev.interactive = true;
    [self appendChild:[_next wireUp]];
    [self appendChild:[_prev wireUp]];

    float bw = (_next.gridWidth * BUTTON_SCALE) / 2.0; // position is center of thing
    float cw = CUBE_WIDTH / 2.0;
    _next.position = (GLKVector3){  cw, -(bw+cw), 0 };
    _prev.position = (GLKVector3){ -cw, -(bw+cw), 0 };
    
    return self;
}

-(void)createTexture
{
    self.texture = _fbo; // [[Texture alloc] initWithFileName:@"uvWrap.png"];
}

-(void)createBuffer
{
    self.color = (GLKVector4){ 0.4, 0.4, 0.6, 1.0 };
    Cube * cube = [Cube cubeWithWidth:CUBE_WIDTH
                  andIndicesIntoNames:@[@(gv_pos),@(gv_uv),@(gv_normal)]
                             andDoUVs:true
                         andDoNormals:true
                             wrapType:kCubeWrapHorizontal];
    [self addBuffer:cube];
}

-(void)configureLighting
{
    if( !self.light )
        self.light = [Light new]; // defaults are good
    self.light.ambientColor = (GLKVector4){0.8, 0.8, 0.8, 1};
    self.light.direction = (GLKVector3){ -1, 0, 0 };
}

-(void)isPrevNext
{
    GenericWithTexture * button = [EventCapture getGraphViewTapChildElementOf:self];
    if( button == _prev )
        [self rotateToNextFace:(CGPoint){-1,0}];
    else if( button == _next )
        [self rotateToNextFace:(CGPoint){1,0}];
}

-(void)didAttachToView:(GraphView *)view
{
    [_eqPanel didAttachToView:view];
    
    [view watchForGlobals:@{ kParamPad3:^{ [self rotateToNextFace:[Global sharedInstance].paramPad3]; },
                             kParamPad1:^{ [self isPrevNext]; }
     }];
}

-(void)setCubeRotation:(float)cubeRotation
{
    float rot = GLKMathDegreesToRadians(cubeRotation);
    self.rotation = (GLKVector3){ CUBE_TILT, -rot, 0 };
    _cubeRotation = cubeRotation;
}

-(void)rotateToNextFace:(CGPoint)pt // pt is direction
{
    float rot = (_cubeRotation + (90.0*pt.x) + (90.0*pt.y));
    NSDictionary * params = @{    TWEEN_DURATION: @0.5f,
                                  TWEEN_TRANSITION: TWEEN_FUNC_EASEINSINE,
                                  @"cubeRotation": @(rot),
                                  TWEEN_ON_COMPLETE_SELECTOR: @"doneRotation",
                                  TWEEN_ON_COMPLETE_TARGET: self
                                  };
    
    [Tweener addTween:self withParameters:params];
}

-(void)doneRotation
{
    
}

-(void)update:(NSTimeInterval)dt mixerUpdate:(MixerUpdate *)mixerUpdate
{
    [_eqPanel update:dt mixerUpdate:mixerUpdate];
    [_eqPanel renderToFBO];
    
    [super update:dt mixerUpdate:mixerUpdate];
}

-(void)xrender:(NSUInteger)w h:(NSUInteger)h
{
    
}
@end
