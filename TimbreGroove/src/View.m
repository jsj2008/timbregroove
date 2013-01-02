//
//  View.m
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "View.h"
#import "Camera.h"
#import "Tween.h"
#import "Tweener.h"

@implementation View

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _backcolor = GLKVector4Make(0, 0, 0, 1);
    }
    return self;
}

- (void)setupGL
{
/*
    [EAGLContext setCurrentContext:self.context];
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
*/    
    _graph = [[Graph alloc] init];
    _graph.camera = [[Camera alloc] init];
    _graph.view = self;
    
}

- (void)showScene
{
    _visible = true;
}

- (void)hideScene
{
    _visible = false;
}

- (void)update:(NSTimeInterval)dt
{
    [_graph update:dt];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    NSUInteger w = self.drawableWidth;
    NSUInteger h = self.drawableHeight;
    [_graph.camera setPerspectiveForViewWidth:w andHeight:h];
    
    glClearColor(_backcolor.r,_backcolor.g,_backcolor.b,_backcolor.a);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [_graph render:w h:h];
}


- (void)animateProp: (const char *)prop
          targetVal: (CGFloat)targetVal
               hide:(bool) hideOnComplete;
{
    NSMutableDictionary * params = d(@{   TWEEN_DURATION: @0.5f,
                                     TWEEN_TRANSITION: TWEEN_FUNC_EASEOUTSINE,
                                     @(prop): @(targetVal)
                                     });
    
    if( hideOnComplete )
    {
        [params setObject:@"hideScene" forKey:TWEEN_ON_COMPLETE_SELECTOR];
        [params setObject:self         forKey:TWEEN_ON_COMPLETE_TARGET];
    }
    
    [Tweener addTween:self withParameters:params];
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
- (void)setY:(CGFloat)y
{
    CGRect rc = self.frame;
    rc.origin.y = y;
    self.frame = rc;
}

- (CGFloat)y
{
    return self.frame.origin.y;
}

- (void)setWidth:(CGFloat)width
{
    CGRect rc = self.frame;
    rc.size.width = width;
    self.frame = rc;
}

- (CGFloat)width
{
    return self.frame.size.width;
}

- (void)setHeight:(CGFloat)height
{
    CGRect rc = self.frame;
    rc.size.height = height;
    self.frame = rc;
}

- (CGFloat)height
{
    return self.frame.size.height;
}

@end
