//
//  MenuView.m
//  TimbreGroove
//
//  Created by victor on 12/18/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "MenuView.h"
#import <OpenGLES/ES2/gl.h>
#import "TGElementGraph.h"
#import "TGCamera.h"
#import "Menu.h"
#import "TGiTween.h"
#import "TGiTweener.h"
#import "TGViewController.h"

@interface MenuView () {
    TGElement * _graph;
}
@property (nonatomic) float x;
@end

@implementation MenuView

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    _graph = [[TGElementGraph alloc] init];
    _graph.camera = [[TGCamera alloc] init];
    
    GLKVector3 pos = { 0, 0, -10 };
    _graph.camera.position = pos;
    
    TGElement * e = [[Menu alloc]init];
    [_graph appendChild:e];
}

- (void)update:(NSTimeInterval)dt
{
    if( !_visible )
        return;
    [_graph update:dt];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    glClearColor(0.0f, 0.0f, 0.0f, 0.7f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    NSUInteger w = self.drawableWidth;
    NSUInteger h = self.drawableHeight;
    [_graph.camera setPerspectiveForViewWidth:w andHeight:h];
    
    [_graph render:w h:h];
}

- (void)setX:(float)x
{
    CGRect rc = self.frame;
    rc.origin.x = x;
    self.frame = rc;
}

-(float)x
{
    CGRect rc = self.frame;
    return rc.origin.x;
}

- (void)show
{    
    _visible = true;
    
    NSDictionary * params = @{  TWEEN_DURATION: @0.5f,
                              TWEEN_TRANSITION: TWEEN_FUNC_EASEOUTSINE,
                                          @"x": @(0)
                            };
    
    [TGiTweener addTween:self withParameters:params];
}

- (void)markHidden
{
    _visible = false;
    [self deleteDrawable];
}

- (void)hide
{
    CGRect rc = self.frame;
    NSDictionary * params = @{  TWEEN_DURATION: @0.5f,
                              TWEEN_TRANSITION: TWEEN_FUNC_EASEOUTSINE,
                                          @"x": @(-rc.size.width),
                    TWEEN_ON_COMPLETE_SELECTOR: @"markHidden",
                      TWEEN_ON_COMPLETE_TARGET:self
                };
    
    [TGiTweener addTween:self withParameters:params];    
}

- (void)onTap:(UITapGestureRecognizer *)tgr
{
    NSLog(@"menu tap");
}

@end
