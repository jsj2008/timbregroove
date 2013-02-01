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

@interface ViewDelegateProxy : NSObject<ViewDelegate> {
        NSMutableArray * _delegates;
}
-(void)addDelegate:(id<ViewDelegate>)delegate;
@end

@implementation ViewDelegateProxy

-(void)addDelegate:(id<ViewDelegate>)delegate
{
    if( !_delegates )
        _delegates = [NSMutableArray new];
    [_delegates addObject:delegate];
}

-(void)p_notifyDelegates:(SEL)selector view:(View *)view
{
    for( id<ViewDelegate> delegate in _delegates )
    {
        if( [delegate respondsToSelector:selector]  )
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [delegate performSelector:selector withObject:view];
#pragma clang diagnostic pop
    }
}

-(void)tgViewWillAppear:(View *)view
{
    [view setupGL]; // yea??
    view.hidden = NO;
    [self p_notifyDelegates:_cmd view:view];
}

-(void)tgViewWillDisappear:(View *)view
{
    [self p_notifyDelegates:_cmd view:view];
}

-(void)tgViewIsFullyVisible:(View *)view
{
    [self p_notifyDelegates:_cmd view:view];
}

-(void)tgViewIsOutofSite:(View *)view
{
    view.hidden = YES;
    [self p_notifyDelegates:_cmd view:view];
    [view deleteDrawable];
}

@end

@interface View() {
    ViewDelegateProxy * _proxy;
}

@end
@implementation View

- (id)initWithFrame:(CGRect)frame context:(EAGLContext *)context;
{
    self = [super initWithFrame:frame context:context];
    if (self) {
        _backcolor = (GLKVector4){0, 0, 0, 1};
        _desiredFrame = frame;
        
        _proxy = [ViewDelegateProxy new];

        // THIS MUST BE LEFT AS DEFAULT!
        // (otherwise the context is not setup properly)
        //self.enableSetNeedsDisplay = NO;
        
        _graph = [[Graph alloc] init];
        _graph.camera = [[Camera alloc] init];
        _graph.view = self;
    }
    return self;
}

-(void)addDelegate:(id<ViewDelegate>)delegate
{
    [_proxy addDelegate:delegate];
}

- (void)setupGL
{
    EAGLContext * ctx = [EAGLContext currentContext];
    if (ctx != self.context)
    {
        if( [EAGLContext setCurrentContext:self.context] )
        {
           // NSLog(@"Set context %@ from %@",self.context,ctx);
        }
        else
        {
            NSLog(@"setting context FAILED: %@",self.context);
            exit(-1);
        }
    }
    else
    {
        // NSLog(@"Did NOT Set context %@",self.context);
    }

    GLint src,dst;
    glGetIntegerv(GL_BLEND_SRC, &src);
    glGetIntegerv(GL_BLEND_DST, &dst);
    if( !glIsEnabled(GL_DEPTH_TEST) )
        glEnable(GL_DEPTH_TEST);
    if( !glIsEnabled(GL_BLEND) )
        glEnable(GL_BLEND);
    if( src != GL_SRC_ALPHA || dst != GL_ONE_MINUS_SRC_ALPHA )
       glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

- (id)firstNode
{
    return _graph.firstChild;
}

- (void)update:(NSTimeInterval)dt
{
    [_graph update:dt];
    [self setNeedsDisplay];
}


-(void)drawRect:(CGRect)rect
{    
    NSUInteger w = self.drawableWidth;
    NSUInteger h = self.drawableHeight;
    [_graph.camera setPerspectiveForViewWidth:w andHeight:h];
    
    glClearColor(_backcolor.r,_backcolor.g,_backcolor.b,_backcolor.a);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    [_graph render:w h:h];
}

- (void)shrinkToNothing
{
    float      valX = self.frame.size.width  / 2.0;
    float      valY = self.frame.size.height / 2.0;
    float      dur  = 1.2;
    NSString * func = TWEEN_FUNC_EASEOUTBOUNCE;

    [_proxy tgViewWillDisappear:self];
    
    [self animateProp:"x"      targetVal:valX notifySelector:@selector(tgViewIsOutofSite:) duration:dur transition:func];
    [self animateProp:"y"      targetVal:valY notifySelector:nil duration:dur transition:func];
    [self animateProp:"width"  targetVal:0    notifySelector:nil duration:dur transition:func];
    [self animateProp:"height" targetVal:0    notifySelector:nil duration:dur transition:func];
}

- (void)showFromDir:(int)dir
{
    [_proxy tgViewWillAppear:self];
    
    if( dir == SHOW_NOW )
    {
        [_proxy tgViewIsFullyVisible:self];
    }
    else
    {
        // BUG: this doesn't for non-screen views appearing from the right
        
        // put this view offscreen
        CGRect rc = self.frame;
        rc.origin.x = rc.size.width * dir;
        self.frame = rc;
        
        [self animateProp:"x" targetVal:_desiredFrame.origin.x notifySelector:@selector(tgViewIsFullyVisible:)];
    }
    
}

- (void)hideToDir:(int)dir
{
    [_proxy tgViewWillDisappear:self];
    
    if( dir == HIDE_NOW )
    {
        [_proxy tgViewIsOutofSite:self];
    }
    else
    {
        // BUG: this doesn't for non-screen views hiding to the right
        
        float val = self.frame.size.width * dir;
        [self animateProp:"x" targetVal:val notifySelector: @selector(tgViewIsOutofSite:)];
    }
}

- (void)animateProp: (const char *)prop
          targetVal: (float)targetVal
     notifySelector: (SEL)selector
{
    [self animateProp:prop targetVal:targetVal notifySelector:selector duration:0.5 transition:TWEEN_FUNC_EASEOUTSINE];
}

- (void)animateProp: (const char *)prop
          targetVal: (float)targetVal
     notifySelector: (SEL)selector
           duration: (float)duration
         transition: (NSString *)transition
{
    NSMutableDictionary * params = d(@{   TWEEN_DURATION: @(duration),
                                     TWEEN_TRANSITION: transition,
                                     @(prop): @(targetVal)
                                     });

    if( selector )
    {
        params[TWEEN_ON_COMPLETE_TARGET]   = _proxy;
        params[TWEEN_ON_COMPLETE_SELECTOR] = NSStringFromSelector(selector);
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
