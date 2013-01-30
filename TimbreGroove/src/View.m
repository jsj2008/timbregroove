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

- (id)initWithFrame:(CGRect)frame context:(EAGLContext *)context;
{
    self = [super initWithFrame:frame context:context];
    if (self) {
        _backcolor = GLKVector4Make(0, 0, 0, 1);
    }
    return self;
}


- (void)setupGL
{
    if( [EAGLContext currentContext] != self.context )
    {
        [EAGLContext setCurrentContext:self.context];
        NSLog(@"Set context %@",self.context);
    }
    else
    {
        NSLog(@"Did NOT Set context %@",self.context);
    }
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
   
    if( !_graph )
    {
        _graph = [[Graph alloc] init];
        _graph.camera = [[Camera alloc] init];
        _graph.view = self;
    }
}

-(bool)isInFullView
{
    CGRect rc = self.frame;
    return rc.origin.x == 0;
}

- (id)firstNode
{
    return _graph.firstChild;
}

- (void)update:(NSTimeInterval)dt
{
    if( self.inFullView )
    {
        [_graph update:dt];
        [self setNeedsDisplay];
    }
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

-(void)hideAnimationComplete
{
    _visible = false;
    _hiding = false;
    [self deleteDrawable];
}

- (void)shrinkToNothing:(id)target notify:(NSString *)notify
{
    CGSize sz = self.frame.size;
    CGFloat midX = sz.width / 2.0f;
    CGFloat midY = sz.height / 2.0f;
    NSDictionary * params = @{    TWEEN_DURATION: @1.2f,
                                TWEEN_TRANSITION: TWEEN_FUNC_EASEOUTBOUNCE,
                                TWEEN_ON_COMPLETE_SELECTOR: notify,
                                TWEEN_ON_COMPLETE_TARGET: target,
                                    @"x": @(midX)
                            };

    [Tweener addTween:self withParameters:params];

    NSDictionary * params2 = @{    TWEEN_DURATION: @1.2f,
                                 TWEEN_TRANSITION: TWEEN_FUNC_EASEOUTBOUNCE,
                                             @"y": @(midY)
                                    };
    
    [Tweener addTween:self withParameters:params2];

    NSDictionary * params3 = @{    TWEEN_DURATION: @1.2f,
        TWEEN_TRANSITION: TWEEN_FUNC_EASEOUTBOUNCE,
        @"width": @(0)
    };
    
    [Tweener addTween:self withParameters:params3];

    NSDictionary * params4 = @{    TWEEN_DURATION: @1.2f,
        TWEEN_TRANSITION: TWEEN_FUNC_EASEOUTBOUNCE,
    @"height": @(0)
    };
    
    [Tweener addTween:self withParameters:params4];

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
        self.hiding = true;
        [params setObject:@"hideAnimationComplete" forKey:TWEEN_ON_COMPLETE_SELECTOR];
        [params setObject:self                     forKey:TWEEN_ON_COMPLETE_TARGET];
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
