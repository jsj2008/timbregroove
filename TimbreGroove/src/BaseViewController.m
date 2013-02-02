//
//  TGBaseViewController.m
//  TimbreGroove
//
//  Created by victor on 2/1/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "BaseViewController.h"
#import "View.h"

@interface BaseViewController () {
}

@end

@implementation BaseViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    View *view = self.viewview;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
    self.preferredFramesPerSecond = 60;
}

-(View *)viewview
{
    return (View *)self.view;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

-(void)startGL
{
}

- (void)tearDownGL
{
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    View * view = (View*)self.view;
    if( view.hidden || view.superview.hidden )
        return;
    
    NSTimeInterval dt = self.timeSinceLastUpdate;
    [view update:dt];
}

- (void)glkView:(GLKView *)glkView drawInRect:(CGRect)rect
{
    View * view = (View*)glkView;
    if( view.hidden || view.superview.hidden )
        return;
    
    [view render];
}

@end
