//
//  TGBaseViewController.m
//  TimbreGroove
//
//  Created by victor on 2/1/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "TGBaseViewController.h"
#import "Graph.h"
#import "Camera.h"

@interface TGBaseViewController () {

}

@end

@implementation TGBaseViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    NSLog(@"Created Context: %@", self.context);
    View *view = self.viewview;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
    self.preferredFramesPerSecond = 30;
    
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

- (void)tearDownGL
{
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
}

- (void)startGL
{
    
}

-(id)createNode:(NSDictionary *)params
{
    Class klass = NSClassFromString(params[@"instanceClass"]);
    TG3dObject * node = [[klass alloc] init];
    View * view = self.viewview;
    node.view = view;
    [view.graph appendChild:node];
    [node setValuesForKeysWithDictionary:params];
    [node wireUp];
    return node;
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    [self.viewview update:self.timeSinceLastUpdate];    
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [EAGLContext setCurrentContext:self.context];

    [((View *)view) render];
}

@end
