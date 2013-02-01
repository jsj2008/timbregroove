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
    [self.graph appendChild:e];
    [e wireUp];
    
    return e;
}

- (Menu *)menu
{
    return [self.graph firstChild];
}

-(void)setLevel:(unsigned int)level
{
    _level = level;
    CGRect rc = self.frame;
    rc.origin.x = rc.size.width * level;
    self.desiredFrame = rc;
}

-(void)tgViewWillAppear:(View *)view
{
    if( view == self )
        [self.graph update:0]; // yea, hacky (for enable/disable)
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
