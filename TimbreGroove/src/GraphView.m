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

@interface GraphView () {
}
@end

@implementation GraphView

- (id)initWithFrame:(CGRect)frame context:(EAGLContext *)context;
{
    self = [super initWithFrame:frame context:context];
    if (self) {
        [self wireUp];
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
}

-(void)record:(RecordGesture *)upg
{
}

-(void)tapRecord:(TapRecordGesture *)trg
{
    
}

- (void)update:(NSTimeInterval)dt
{
    [_graph update:dt];
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