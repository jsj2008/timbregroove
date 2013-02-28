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
@dynamic recordGesture;
@dynamic tapRecordGesture;

-(void)setRecordGesture:(RecordGesture *)recordGesture
{
    _recordGesture = recordGesture;
}
-(RecordGesture *)recordGesture
{
    return _recordGesture;
}
-(void)setTapRecordGesture:(TapRecordGesture *)tapRecordGesture
{
    _tapRecordGesture = tapRecordGesture;
}
-(TapRecordGesture *)tapRecordGesture
{
    return _tapRecordGesture;
}

-(void)setupTouches
{
    _recordGesture = [[RecordGesture alloc] initWithTarget:self action:@selector(record:)];
    [self addGestureRecognizer:_recordGesture];
    
    _tapRecordGesture = [[TapRecordGesture alloc] initWithTarget:self action:@selector(tapRecord:)];
    [self addGestureRecognizer:_tapRecordGesture];
    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self addGestureRecognizer:tap];
    
    UIPinchGestureRecognizer * pnch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    [self addGestureRecognizer:pnch];
    
    PannerGesture * pgr = [[PannerGesture alloc] initWithTarget:self action:@selector(panning:)];
    [self addGestureRecognizer:pgr];
    pgr.limitRC = self.frame;
    
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
        Scene * scene = [Global sharedInstance].scene;
        [scene setTrigger:kTriggerDirection point:pt];
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
        [[Global sharedInstance].scene setTrigger:kTriggerPinch value:scale];
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
        Scene * scene   = [Global sharedInstance].scene;
        CGPoint pt      = [tgr locationInView:self];
        [scene setTrigger:kTriggerTapPos point:pt];
        [scene setTrigger:kTriggerTap1 point:[self nativeToTG:pt]];
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

        Scene * scene   = [Global sharedInstance].scene;
        
        CGPoint spt = (CGPoint){ (pt.x - _panLast.x) / sz.width,
                                -(pt.y - _panLast.y) / sz.height };

        // we get a ton of 0 movement
        if( fabsf(spt.x) > FLT_EPSILON )
        {
//            NSLog(@"Pan x: %f for pt:%d,%d", spt.x, (int)pt.x, (int)pt.y);
            [scene setTrigger:kTriggerPanX value:spt.x];
        }
        if( fabsf(spt.y) > FLT_EPSILON )
            [scene setTrigger:kTriggerPanY value:spt.y];
        [scene setTrigger:kTriggerDrag1 point:[self nativeToTG:pt]];
        [scene setTrigger:kTriggerDragPos point:pt];
        
        _panLast = pt;
    }
    else
    {
        _panTracking = false;
    }
}

-(void)record:(RecordGesture *)upg
{
}

-(void)tapRecord:(TapRecordGesture *)trg
{
    
}

@end
