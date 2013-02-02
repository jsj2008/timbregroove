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
}

- (Menu *)createMenu:(NSDictionary *)meta
{
    Menu * e = [[Menu alloc] init];
    e.meta = meta;
    e.view = self;
    [self.graph appendChild:e];
    [e wireUp];
    
    return e;
}

- (Menu *)menu
{
    return [self.graph firstChild];
}

- (void)onTap:(UITapGestureRecognizer *)tgr
{
    if( tgr.state == UIGestureRecognizerStateEnded )
    {
        CGPoint pt = [tgr locationInView:self];
        TG3dObject<Interactive> * e = [[EventCapture new] childElementOf:self.graph fromScreenPt:pt];
        [e onTap:tgr];
        [self setNeedsDisplay];
    }
}

@end
