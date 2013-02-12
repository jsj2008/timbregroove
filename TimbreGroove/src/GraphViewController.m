//
//  TGBaseViewController.m
//  TimbreGroove
//
//  Created by victor on 2/1/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "GraphView.h"
#import "Graph.h"
#import "Mixer.h"

@interface GraphViewController : GLKViewController
@property (nonatomic,strong) EAGLContext * context;
@end

@interface GraphViewController () {
}

@end

@implementation GraphViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.preferredFramesPerSecond = 60;
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    GLKView * view = (GLKView *)self.view;
    view.context = _context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;

    [EAGLContext setCurrentContext:_context];
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    [[Mixer sharedInstance] fetchAudioFrame];
    
    [(GraphView*)self.view update:self.timeSinceLastUpdate];
}

- (void)glkView:(GLKView *)glkView drawInRect:(CGRect)rect
{
    [(GraphView*)glkView render];
}

@end
