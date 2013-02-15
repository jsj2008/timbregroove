//
//  View.m
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "GraphView.h"
#import "Camera.h"
#import "Tween.h"
#import "Tweener.h"
#import "RecordGesture.h"
#import "Mixer.h"
#import "Mixer+Diag.h"
#import "Mixer+Parameters.h"
#define CLAMP_TO_0_1(x) (x < 0.0 ? 0.0 : x > 1.0 ? 1.0 : x)

@interface GraphView () {
    eqBands _gotEQBand;
}
@end

@implementation GraphView

- (id)initWithFrame:(CGRect)frame context:(EAGLContext *)context;
{
    self = [super initWithFrame:frame context:context];
    if (self) {
        [self wireUp];
        _gotEQBand = -1;
        
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self wireUp];
    }
    return self;
}

-(void)wireUp
{
    _backcolor = (GLKVector4){0, 0, 0, 1};

    self.opaque = YES;
    
    _recordGesture = [[RecordGesture alloc] initWithTarget:self action:@selector(record:)];
    [self addGestureRecognizer:_recordGesture];
    
    _tapRecordGesture = [[TapRecordGesture alloc] initWithTarget:self action:@selector(tapRecord:)];
    [self addGestureRecognizer:_tapRecordGesture];
    
    UIPanGestureRecognizer * pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(userParam:)];
    [self addGestureRecognizer:pgr];
}

-(void)userParam:(UIPanGestureRecognizer *)pgr
{
    if( pgr.state == UIGestureRecognizerStateChanged )
    {
        Mixer * mixer = [Mixer sharedInstance];
        CGSize sz = self.frame.size;
        
        CGPoint tpt = [pgr translationInView:self];
        tpt.x /= sz.width;
        tpt.y /= -sz.height;
        AudioUnitParameterValue peak = tpt.y / 2.0;
        if( _gotEQBand == -1 )
        {
            CGPoint pt = [pgr locationInView:self];
            pt.x /= sz.width;
            _gotEQBand = pt.x < 0.5 ? kEQLow : kEQHigh;
            mixer.selectedEQBand = _gotEQBand;
        }

        //NSLog(@"translation: %f,%f  band: %d", tpt.x, tpt.y, _gotEQBand);

        mixer.eqBandwidth = CLAMP_TO_0_1(tpt.y);
        mixer.eqCenter = CLAMP_TO_0_1(tpt.x);
        mixer.eqPeak = CLAMP_TO_0_1(peak);
        
        // from mixer+diag
        [mixer dumpEQ];
    }
    else
    {
        _gotEQBand = -1;
    }
}

-(void)record:(RecordGesture *)upg
{
}

-(void)tapRecord:(TapRecordGesture *)trg
{
    
}

- (void)update:(NSTimeInterval)dt mixerUpdate:(MixerUpdate *)mixerUpdate
{
    [_graph update:dt mixerUpdate:mixerUpdate];
}

-(void)setGraph:(Graph *)graph
{
    if( _graph )
        [_graph traverse:@selector(didDetachFromView:) userObj:self];
    _graph = graph;
    _graph.view = self;
    [_graph traverse:@selector(didAttachToView:) userObj:self];
}

-(void)render // drawRect:(CGRect)rect
{
    NSUInteger w = self.drawableWidth;
    NSUInteger h = self.drawableHeight;
    [_graph.camera setPerspectiveForViewWidth:w andHeight:h];
    
    glClearColor(_backcolor.r,_backcolor.g,_backcolor.b,_backcolor.a);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    [_graph render:w h:h];
}

-(NSArray *)getSettings
{
    return [_graph getSettings];
}

-(void)commitSettings
{
    [_graph settingsChanged];
}

@end
