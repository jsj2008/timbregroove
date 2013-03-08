//
//  GraphView+Touches.m
//  TimbreGroove
//
//  Created by victor on 2/19/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "GraphView+Touches.h"
#import "Gestures.h"
#import "Global.h"
#import "Scene.h"
#import "Names.h"

@implementation GraphView (Touches)

-(void)triggersChanged:(Scene *)scene
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
    
    [self setupTouches];
}

-(void)setupTouches
{
    if( _triggerTap1 || _triggerTapPos )
    {
        UITapGestureRecognizer * tap;
        tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        [self addGestureRecognizer:tap];
    }
    
    if( _triggerPinch )
    {
        UIPinchGestureRecognizer * pnch;
        pnch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
        [self addGestureRecognizer:pnch];
    }
    
    if( _triggerPanX || _triggerPanY || _triggerDrag1 || _triggerDragPos )
    {
        PannerGesture * pgr;
        pgr = [[PannerGesture alloc] initWithTarget:self action:@selector(panning:)];
        [self addGestureRecognizer:pgr];
        pgr.limitRC = self.frame;
    }
    
    if( _triggerDirection )
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
        _triggerDirection(pt);
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
        _triggerPinch(scale);
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
        if( _triggerTapPos )
            _triggerTapPos(pt);
        if( _triggerTap1 )
            _triggerTap1([self nativeToTG:pt]);
    }
}

-(void)panning:(UIPanGestureRecognizer *)pgr
{
    if( pgr.state == UIGestureRecognizerStateChanged )
    {
        CGSize sz       = self.frame.size;
        CGPoint pt      = [pgr locationInView:self];
        
        if( !_panTracking )
        {
            _panLast = pt;
            _panTracking = true;
        }

        CGPoint spt = (CGPoint){ (pt.x - _panLast.x) / sz.width,
                                -(pt.y - _panLast.y) / sz.height };

        // we get a ton of 0 movement
        if( fabsf(spt.x) > FLT_EPSILON && _triggerPanX )
            _triggerPanX(spt.x);
        if( fabsf(spt.y) > FLT_EPSILON && _triggerPanY )
            _triggerPanY(spt.y);

        if( _triggerDrag1 )
            _triggerDrag1([self nativeToTG:pt]);
        if( _triggerDragPos )
            _triggerDragPos(pt);
        
        _panLast = pt;
    }
    else
    {
        _panTracking = false;
    }
}

@end
