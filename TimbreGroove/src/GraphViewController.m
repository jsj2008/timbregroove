//
//  TGBaseViewController.m
//  TimbreGroove
//
//  Created by victor on 2/1/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "GraphView.h"
#import "Graph.h"

@interface GraphViewController : GLKViewController
@end

@interface GraphViewController () {
}

@end

@implementation GraphViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.preferredFramesPerSecond = 60;
}

-(GraphView *)viewview
{
    return (GraphView *)self.view;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tearDownGL
{
    GLKView * view = (GLKView *)self.view;
    if ([EAGLContext currentContext] == view.context) {
        [EAGLContext setCurrentContext:nil];
    }    
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    GraphView * view = (GraphView*)self.view;
    NSTimeInterval dt = self.timeSinceLastUpdate;
    [view update:dt];
}

- (void)glkView:(GLKView *)glkView drawInRect:(CGRect)rect
{
    GraphView * view = (GraphView*)glkView;
    [view render];
}

@end
