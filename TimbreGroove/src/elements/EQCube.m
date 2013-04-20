//
//  SpinCube.m
//  TimbreGroove
//
//  Created by victor on 2/17/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Cube.h"
#import "EQPanel.h"
#import "FBO.h"
#import "Light.h"
#import "GraphView.h"
#import "GenericWithTexture.h"
#import "EventCapture.h"

#import "Scene.h"
#import "Names.h"
#import "Audio.h"
#import "SoundSystemParameters.h"

#define CUBE_TILT  0.1
#define CUBE_SIZE 1.8
#define BUTTON_SCALE 0.25
#define CUBE_GUTTER_PADDING (CUBE_SIZE * 0.09)
#define EQ_PANEL_HEIGHT 256

NSString const * kParamRotateCube  = @"RotateCube";

@interface EQCube : Generic  {
    EQPanel * _eqPanel;
    
    GenericWithTexture * _next;
    GenericWithTexture * _prev;
    
    FloatParameter  * _rotateParam;
    FloatParamBlock   _rotateTrigger;
    
    IntParamBlock _eqLowEnable;
    IntParamBlock _eqMidEnable;
    IntParamBlock _eqHighEnable;
}
@property (nonatomic) int currentBand;
@end

@implementation EQCube

-(id)wireUp
{
    [super wireUp];

    [self setupButtons];
    
    self.position = (GLKVector3){ 0, CUBE_TILT/2.0, 0 };
    
    return self;
}

-(void)setupButtons
{
    _next = [[GenericWithTexture alloc] initWithText:@"Next -->"];
    _prev = [[GenericWithTexture alloc] initWithText:@"<-- Prev"];
    
    _next.scaleXYZ = BUTTON_SCALE;
    _next.interactive = true;
    _prev.scaleXYZ = BUTTON_SCALE;
    _prev.interactive = true;
    [self appendChild:[_next wireUp]];
    [self appendChild:[_prev wireUp]];

    float bw = (_next.gridWidth * BUTTON_SCALE) / 2.0; // position is center of thing
    float cw = CUBE_SIZE / 2.0;
    float y = -(bw+cw+CUBE_GUTTER_PADDING);
    _next.position = (GLKVector3){  cw, y, 0 };
    _prev.position = (GLKVector3){ -cw, y, 0 };
    
}

-(void)createShader
{
    _eqPanel = [[EQPanel alloc] init];
    
    Texture * texture = [[FBO alloc] initWithObject:_eqPanel
                                         width:EQ_PANEL_HEIGHT * 4
                                        height:EQ_PANEL_HEIGHT];
    

    Light *light = [Light new];
    light.directional = true;
    light.position = (GLKVector3){ 0.5, 1, -0.5 };
    [self.lights addLight:light];
    
    Material * mat = [Material withColor:(GLKVector4){0.2, 0.2, 0.2, 1}];
    
    [self addShaderFeature:texture];
    [self addShaderFeature:mat];
    [super createShader];
}

-(void)createBuffer
{
    Cube * cube = [Cube cubeWithWidth:CUBE_SIZE
                  andIndicesIntoNames:@[@(gv_pos),@(gv_uv),@(gv_normal)]
                             andDoUVs:true
                         andDoNormals:true
                             wrapType:kCubeWrapHorizontal];
    [self addBuffer:cube];
}

-(void)isPrevNext:(CGPoint) pt
{
    UIView * view = self.view;
    GenericWithTexture * button = [EventCapture getGraphViewTapChildElementOf:self
                                                                       inView:view
                                                                         atPt:pt];
    if( button == _prev )
        [self rotateToNextFace:-1];
    else if( button == _next )
        [self rotateToNextFace:1];
}

-(void)getParameters:(NSMutableDictionary *)parameters
{
    [super    getParameters:parameters];
    
    [_eqPanel getParameters:parameters];
    
    parameters[@"Buttons"] = [Parameter withBlock:^(CGPoint pt){
        [self isPrevNext:pt];
    }];

    // -90 is where 'EQ OFF' is
    Parameter * param = [FloatParameter withValue:-90
                                       block:^(float f){
                                           [self setRotation:
                                            (GLKVector3){ CUBE_TILT, -GLKMathDegreesToRadians(f), 0 }];
 
                                       }];
    
    // I have to say: I don't know why his param needs a 'force'
    // and the one above here doesn't. (Hint: it has something
    // to do with wrapping a tweener around it below)
    param.forceDecommision = true;
    
    parameters[kParamRotateCube] = param;
    
}

-(void)triggersChanged:(Scene *)scene
{
    [super    triggersChanged:scene];
    [_eqPanel triggersChanged:scene];
    
    TriggerMap * tm = scene.triggers;
    
    if( scene )
    {
        _rotateTrigger = [tm getFloatTrigger:[kParamRotateCube stringByAppendingTween:kTweenEaseOutThrow len:0.5]];
 
        _eqLowEnable  = [tm getIntTrigger:kParamEQLowPassEnable];
        _eqMidEnable  = [tm getIntTrigger:kParamEQParametricEnable];
        _eqHighEnable = [tm getIntTrigger:kParamEQHiPassEnable];
        
        SoundSystemParameters * ssp = scene.audio.ssp;
        // we're at -90 right now
        _currentBand = [ssp whichEQBandisEnabled] + 1;
        if( _currentBand )
            _rotateTrigger( _currentBand * 90 );
    }
    else
    {
        _rotateTrigger = nil;
        _eqLowEnable = nil;
        _eqMidEnable = nil;
        _eqHighEnable = nil;
    }
    
}

-(void)rotateToNextFace:(int)direction
{
    int band = _currentBand;
    band += direction;
    if( band < eqbNone )
        band = eqbHigh;
    if( band > eqbHigh )
        band = eqbNone;
    [self enableEQ:_currentBand value:0];
    _currentBand = band;
    [self enableEQ:_currentBand value:1];
    _eqPanel.band = _currentBand;
    _rotateTrigger( direction * 90 );
}

-(void)enableEQ:(int)band value:(int)value
{
    switch (band) {
        case eqbLow:
            _eqLowEnable(value);
            break;
        case eqbMid:
            _eqMidEnable(value);
            break;
        case eqbHigh:
            _eqHighEnable(value);
            break;
        default:
            break;
    }
}

-(void)update:(NSTimeInterval)dt
{
    [_eqPanel update:dt];
    [_eqPanel renderToFBO];
    
    [super update:dt];
}


@end
