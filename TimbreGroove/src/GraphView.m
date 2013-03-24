//
//  View.m
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "GraphView.h"
#import "Global.h"
#import "Camera.h"
#import "Scene.h"


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
}

-(void)graphChanged
{
    [_scene wireUp:true];
    [self triggersChanged:_scene];
}

- (void)update:(NSTimeInterval)dt
{
    [_graph update:dt];
}

-(void)setGraph:(Graph *)graph
{
    _graph = graph;
    _graph.view = self;
}

-(void)setScene:(Scene *)scene
{
    [self triggersChanged:nil];
    _scene = scene;
    self.graph = scene.graph;
    if( _graph.viewBasedParameters )
    {
        NSDictionary * wrappedParams = [_graph.viewBasedParameters map:^id(NSString *name, Parameter * parameter) {
            return [self paramWrapperForObject:parameter.targetObject parameter:parameter];
        }];
        [scene.triggers addParameters:wrappedParams];
        [scene triggersChanged];
    }
    [self triggersChanged:scene];
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

-(void)commitSettings
{
    [_graph settingsChanged];
}

@end
