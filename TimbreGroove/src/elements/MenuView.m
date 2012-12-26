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
    
    _backcolor = GLKVector4Make(0.2, 0.2, 0.2, 0.7);
    GLKVector3 pos = { 0, 0, MENU_CAMERA_Z };
    _graph.camera.position = pos;
}

- (Menu *)createMenu:(NSDictionary *)meta
{
    Menu * e = [[Menu alloc] initWithMeta:meta];
    [_graph appendChild:e];
    
    return e;
}

- (Menu *)menu
{
    return (Menu *)([_graph children][0]);
}


- (void)show
{    
    _visible = true;
    
    unsigned int targetX = self.frame.size.width * _level;
    
    NSDictionary * params = @{  TWEEN_DURATION: @0.5f,
                              TWEEN_TRANSITION: TWEEN_FUNC_EASEOUTSINE,
                                          @"x": @(targetX)
                            };
    
    [Tweener addTween:self withParameters:params];
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
                              TWEEN_TRANSITION: TWEEN_FUNC_EASEOUTTHROW,
                                          @"x": @(-rc.size.width),
                    TWEEN_ON_COMPLETE_SELECTOR: @"markHidden",
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

@end
