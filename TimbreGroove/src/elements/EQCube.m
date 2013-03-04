//
//  SpinCube.m
//  TimbreGroove
//
//  Created by victor on 2/17/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Generic.h"
#import "Cube.h"
#import "EQPanel.h"
#import "FBO.h"
#import "Light.h"
#import "GraphView.h"
#import "SoundSystem.h"
#import "SoundSystem+Parameters.h"
#import "Global.h"
#import "GenericWithTexture.h"
#import "EventCapture.h"


#define CUBE_TILT  0.1
#define CUBE_SIZE 1.8
#define BUTTON_SCALE 0.25
#define CUBE_GUTTER_PADDING (CUBE_SIZE * 0.09)
#define EQ_PANEL_HEIGHT 256

@interface EQCube : Generic  {
    EQPanel * _eqPanel;
    FBO * _fbo;
    GenericWithTexture * _next;
    GenericWithTexture * _prev;
    int _currentBand;
    eqBands _bands[kNUM_EQ_BANDS+1];
}
@property (nonatomic) float cubeRotation;
@end

@implementation EQCube

-(id)wireUp
{
    _fbo = [[FBO alloc] initWithWidth:EQ_PANEL_HEIGHT * 4 height:EQ_PANEL_HEIGHT];
    _eqPanel = [[EQPanel alloc] init];
    _eqPanel.fbo = _fbo;
    [_eqPanel wireUp];
    
    [super wireUp];

    [self setupButtons];
    
    int eqband = [SoundSystem sharedInstance].selectedEQBand;
    for( int b = 0; b < kNUM_EQ_BANDS+1; b++ )
    {
        _bands[b] = kEQDisabled + b;
        if( _bands[b] == eqband )
            _currentBand = b;
    }
    _eqPanel.shapeEdit = eqband;

    self.cubeRotation = 90 * eqband;
    
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

-(void)createTexture
{
    self.texture = _fbo; // [[Texture alloc] initWithFileName:@"uvWrap.png"];
}

-(void)createBuffer
{
    self.color = (GLKVector4){ 0.4, 0.4, 0.6, 1.0 };
    Cube * cube = [Cube cubeWithWidth:CUBE_SIZE
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
    self.light.ambientColor = (GLKVector4){0.2, 0.2, 0.2, 1};
    self.light.direction = (GLKVector3){ 0.5, 1, -0.5 };
}

-(void)isPrevNext
{
    UIView * view;
    CGPoint screenPt;
    GenericWithTexture * button = [EventCapture getGraphViewTapChildElementOf:self
                                                                       inView:view
                                                                         atPt:screenPt];
    if( button == _prev )
        [self rotateToNextFace:(CGPoint){-1,0}];
    else if( button == _next )
        [self rotateToNextFace:(CGPoint){1,0}];
}

-(void)didAttachToView:(GraphView *)view
{
    [_eqPanel didAttachToView:view];    
}

-(void)setCubeRotation:(float)cubeRotation
{
    float rot = GLKMathDegreesToRadians(cubeRotation);
    self.rotation = (GLKVector3){ CUBE_TILT, -rot, 0 };
    _cubeRotation = cubeRotation;
}

-(void)doneRotation
{
    eqBands band = _bands[_currentBand];
    _eqPanel.shapeEdit = band;
    [SoundSystem sharedInstance].selectedEQBand = band;
}

-(void)rotateToNextFace:(CGPoint)pt // pt is direction
{
    /*
     float rot = (_cubeRotation + (90.0*pt.x) );
    NSDictionary * params = @{    kTweenDuration: @0.5f,
                                  kTweenFunction: kTweenEaseInSine,
                                  @"cubeRotation": @(rot),
                                  kTweenCompleteBlock: ^{ [self doneRotation]; }
                                  };
    
    [Tweener addTween:self withParameters:params];
    */
    _currentBand = abs((_currentBand + (int)pt.x) % 4);
}


-(void)update:(NSTimeInterval)dt
{
    [_eqPanel update:dt];
    [_eqPanel renderToFBO];
    
    [super update:dt];
}


@end
