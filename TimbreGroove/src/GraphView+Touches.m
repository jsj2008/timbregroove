//
//  GraphView+Touches.m
//  TimbreGroove
//
//  Created by victor on 2/19/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "GraphView+Touches.h"
#import "Global.h"
#import "Scene.h"
#import "Names.h"


@interface ViewTriggers : NSObject {
@public
    PointParamBlock _triggerDirection;
    FloatParamBlock _triggerPinch;
    PointParamBlock _triggerTapPos;
    PointParamBlock _triggerTap1;
    FloatParamBlock _triggerPanX;
    FloatParamBlock _triggerPanY;
    PointParamBlock _triggerDrag1;
    PointParamBlock _triggerDragPos;
    PointParamBlock _triggerDblTap;
}
@end
@implementation ViewTriggers
-(void)triggersChanged:(Scene *)scene
{
    if( scene )
    {
        TriggerMap * tm = scene.triggers;
        _triggerDirection = [tm getPointTrigger:kTriggerDirection];
        _triggerPinch     = [tm getFloatTrigger:kTriggerPinch];
        _triggerTapPos    = [tm getPointTrigger:kTriggerTapPos];
        _triggerTap1      = [tm getPointTrigger:kTriggerTap1];
        _triggerPanX      = [tm getFloatTrigger:kTriggerPanX];
        _triggerPanY      = [tm getFloatTrigger:kTriggerPanY];
        _triggerDrag1     = [tm getPointTrigger:kTriggerDrag1];
        _triggerDragPos   = [tm getPointTrigger:kTriggerDragPos];
        _triggerDblTap    = [tm getPointTrigger:kTriggerDblTap];
    }
    else
    {
        _triggerDirection = nil;
        _triggerPinch     = nil;
        _triggerTapPos    = nil;
        _triggerTap1      = nil;
        _triggerPanX      = nil;
        _triggerPanY      = nil;
        _triggerDrag1     = nil;
        _triggerDragPos   = nil;
        _triggerDblTap    = nil;
    }
}
@end

@implementation GraphView (Touches)

-(void)pushTriggers
{
    _currentTriggers = [ViewTriggers new];
    if( !_triggerStack )
        _triggerStack = [NSMutableArray new];
    [_triggerStack addObject:_currentTriggers];
}

-(void)popTriggers
{
    [_currentTriggers triggersChanged:nil];
    [_triggerStack removeLastObject];
    _currentTriggers = [_triggerStack lastObject];
}

-(void)triggersChanged:(Scene *)scene
{
    if( !_currentTriggers )
        [self pushTriggers];
    
    [_currentTriggers triggersChanged:scene];
    
    if( scene )
    {
        [self setupTouches];
    }
    else
    {
        [[self gestureRecognizers] each:^(UIGestureRecognizer * gr) {
            [self removeGestureRecognizer:gr];
        }];
    }
}

-(void)setupTouches
{
    UITapGestureRecognizer * dblTap = nil;
    
    if( _currentTriggers->_triggerDblTap )
    {
        dblTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dblTap:)];
        dblTap.numberOfTapsRequired = 2;
        [self addGestureRecognizer:dblTap];
    }
    
    if( _currentTriggers->_triggerTap1 || _currentTriggers->_triggerTapPos )
    {
        UITapGestureRecognizer * tap;
        tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        if( dblTap )
           [tap requireGestureRecognizerToFail:dblTap];
        [self addGestureRecognizer:tap];
    }
    
    if( _currentTriggers->_triggerPinch )
    {
        UIPinchGestureRecognizer * pnch;
        pnch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
        [self addGestureRecognizer:pnch];
    }
    
    if( _currentTriggers->_triggerPanX || _currentTriggers->_triggerPanY ||
       _currentTriggers->_triggerDrag1 || _currentTriggers->_triggerDragPos )
    {
        UIPanGestureRecognizer * pgr;
        pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panning:)];
        [self addGestureRecognizer:pgr];
    }
    
    if( _currentTriggers->_triggerDirection )
    {
        UISwipeGestureRecognizerDirection dirs[4] = {
            UISwipeGestureRecognizerDirectionRight,
            UISwipeGestureRecognizerDirectionLeft,
            UISwipeGestureRecognizerDirectionUp,
            UISwipeGestureRecognizerDirectionDown
        };
        UISwipeGestureRecognizer * sgr;
        for( int i = 0; i < 4; i++ )
        {
            sgr = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
            sgr.direction = dirs[i];
            [self addGestureRecognizer:sgr];
        }
    }
}

-(void)swipe:(UISwipeGestureRecognizer *)sgr
{
    if( sgr.state == UIGestureRecognizerStateEnded )
    {
        CGPoint pt = (CGPoint){0,0};
        switch (sgr.direction)
        {
            case UISwipeGestureRecognizerDirectionLeft:
                pt.x = 1;
                break;
            case UISwipeGestureRecognizerDirectionRight:
                pt.x = -1;
                break;
            case UISwipeGestureRecognizerDirectionUp:
                pt.y = 1;
                break;
            case UISwipeGestureRecognizerDirectionDown:
                pt.y = -1;
                break;
        }
        _currentTriggers->_triggerDirection(pt);
    }
}

-(void)pinch:(UIPinchGestureRecognizer *) pnch
{
    if( pnch.state == UIGestureRecognizerStateChanged )
    {
        float scale = pnch.scale;
        if( scale < 0.0 )
        {
            scale = -scale;
        }
        else
        {
            if( scale < 2.0 )
                scale -= 1.0;
            else
                scale = 1.0;
        }
        _currentTriggers->_triggerPinch(scale);
    }
}

-(CGPoint)nativeToTG:(CGPoint)pt
{
    CGSize sz       = self.frame.size;
    pt.x /= sz.width;
    pt.y = 1.0 - (pt.y / sz.height); // up is up damn it
    pt.x = (pt.x - 0.5) * 2.0;
    pt.y = (pt.y - 0.5) * 2.0;
    return pt;
}

-(void)tap:(UITapGestureRecognizer *)tgr
{
    if( tgr.state == UIGestureRecognizerStateEnded )
    {
        CGPoint pt      = [tgr locationInView:self];
        if( _currentTriggers->_triggerTapPos )
            _currentTriggers->_triggerTapPos(pt);
        if( _currentTriggers->_triggerTap1 )
            _currentTriggers->_triggerTap1([self nativeToTG:pt]);
    }
}

-(void)dblTap:(UITapGestureRecognizer *)tgr
{
    if( tgr.state == UIGestureRecognizerStateEnded )
    {
        CGPoint pt = [tgr locationInView:self];
        _currentTriggers->_triggerDblTap([self nativeToTG:pt]);
    }
}

-(void)panning:(UIPanGestureRecognizer *)pgr
{
    if( pgr.state == UIGestureRecognizerStateBegan )
    {
        _panLast = [pgr locationInView:self];
        _panTracking = true;
    }
    else if( pgr.state == UIGestureRecognizerStateChanged )
    {
        CGSize sz       = self.frame.size;
        CGPoint pt      = [pgr locationInView:self];
        
        /*
        CGPoint spt = (CGPoint){ (pt.x - _panLast.x) / sz.width,
                                -(pt.y - _panLast.y) / sz.height };
         */
        
        CGPoint spt = (CGPoint){   (pt.x / sz.width  * 2) - 1.0,
                                 -((pt.y / sz.height * 2) - 1.0)  };

        TGLog(LLJustSayin, @"pt: { %f,%f } scaled: { %f,%f } ",pt.x, pt.y, spt.x,spt.y);
        // we get a ton of 0 movement
        if( fabsf(spt.x) > FLT_EPSILON && _currentTriggers->_triggerPanX )
            _currentTriggers->_triggerPanX(spt.x);
        if( fabsf(spt.y) > FLT_EPSILON && _currentTriggers->_triggerPanY )
            _currentTriggers->_triggerPanY(spt.y);

        if( _currentTriggers->_triggerDrag1 )
            _currentTriggers->_triggerDrag1([self nativeToTG:pt]);
        if( _currentTriggers->_triggerDragPos )
            _currentTriggers->_triggerDragPos(pt);
        
        //_panLast = pt;
    }
    else if( pgr.state == UIGestureRecognizerStateEnded || pgr.state == UIGestureRecognizerStateCancelled )
    {
        _panTracking = false;
    }
}

@end
