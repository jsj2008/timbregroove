//
//  MenuView.m
//  TimbreGroove
//
//  Created by victor on 12/18/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <OpenGLES/ES2/gl.h>
#import "Graph.h"
#import "Camera.h"
#import "EventCapture.h"

#import "Tween.h"
#import "Tweener.h"

#import "Menu.h"
#import "MenuItem.h"
#import "MenuView.h"

@implementation MenuView

- (void)setupGL
{
    [super setupGL];
    
    _backcolor = (GLKVector4){0.3, 0.3, 0.3, 0.7};
}

- (Menu *)createMenu:(NSDictionary *)meta
{
    Menu * e = [[Menu alloc] init];
    e.meta = meta;
    e.view = self;
    [_graph appendChild:e];
    [e wireUp];
    
    return e;
}

- (Menu *)menu
{
    return [_graph firstChild];
}


- (void)show
{    
    _visible = true;
    
    [self setupGL]; // is this right?
    
    [self.graph update:0]; // yea, hacky (for enable/disable)
        
    Menu * menu = self.menu;
    [menu willBecomeVisible];
    
    unsigned int targetX = self.frame.size.width * _level;
    
    NSDictionary * params = @{  TWEEN_DURATION: @0.4f,
                              TWEEN_TRANSITION: TWEEN_FUNC_LINEAR,
                    TWEEN_ON_COMPLETE_SELECTOR: @"isInFullView",
                    TWEEN_ON_COMPLETE_TARGET: self.menu,
                                          @"x": @(targetX)
                            };
    
    [Tweener addTween:self withParameters:params];
}

-(bool)isInFullView
{
    CGRect rc = self.frame;
    return rc.origin.x == rc.size.width * _level;
}

-(void)setX:(float)x
{
    [super setX:x];
    [self setNeedsDisplay];
}

- (void)hide
{
    if( self.hiding )
        return;
    self.hiding = true;
    CGRect rc = self.frame;
    NSDictionary * params = @{  TWEEN_DURATION: @0.5f,
                              TWEEN_TRANSITION: TWEEN_FUNC_EASEOUTTHROW,
                                          @"x": @(-rc.size.width),
                    TWEEN_ON_COMPLETE_SELECTOR: @"hideAnimationComplete",
                      TWEEN_ON_COMPLETE_TARGET: self
                };
    
    [Tweener addTween:self withParameters:params];    
}

- (void)onTap:(UITapGestureRecognizer *)tgr
{
    if( tgr.state == UIGestureRecognizerStateEnded )
    {
        CGPoint pt = [tgr locationInView:self];
        TG3dObject<Interactive> * e = [[EventCapture new] childElementOf:_graph fromScreenPt:pt];
        [e onTap:tgr];
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
    glClearColor(_backcolor.r,_backcolor.g,_backcolor.b,_backcolor.a);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.graph render:rect.size.width h:rect.size.height];
}


@end
