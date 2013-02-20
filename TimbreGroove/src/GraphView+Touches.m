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
 //   [self addGestureRecognizer:pgr];
    pgr.limitRC = self.frame;
    
    UISwipeGestureRecognizerDirection dirs[4] = {
        UISwipeGestureRecognizerDirectionRight,
        UISwipeGestureRecognizerDirectionLeft,
        UISwipeGestureRecognizerDirectionUp,
        UISwipeGestureRecognizerDirectionDown
    };
    UISwipeGestureRecognizer * sgr;
    for( int i = 0; i < 8; i++ )
    {
        sgr = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
        sgr.direction = dirs[i % 4];
        sgr.numberOfTouchesRequired = ((i >> 2) & 1) + 1;
        //[sgr requireGestureRecognizerToFail:pgr];
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
        if( sgr.numberOfTouchesRequired == 2 )
            [Global sharedInstance].paramPad3 = pt;
        else
            [Global sharedInstance].paramPad2 = pt;
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
        [Global sharedInstance].paramKnob3 = scale;
    }
}

-(void)tap:(UITapGestureRecognizer *)tgr
{
    if( tgr.state == UIGestureRecognizerStateEnded )
    {
        CGSize sz       = self.frame.size;
        CGPoint pt      = [tgr locationInView:self];
        [Global sharedInstance].windowTap = pt;
        pt.x /= sz.width;
        pt.y = 1.0 - (pt.y / sz.height); // up is up damn it
        [Global sharedInstance].paramPad1 = pt;
    }
}

-(void)panning:(UIPanGestureRecognizer *)pgr
{
    if( pgr.state == UIGestureRecognizerStateChanged )
    {
        CGSize sz       = self.frame.size;
        CGPoint pt      = [pgr locationInView:self];
        Global * global = [Global sharedInstance];
        
        if( !_panTracking )
        {
            _panLast = pt;
            _panTracking = true;
        }
        
        global.paramKnob1 = (pt.x - _panLast.x) / sz.width;
        global.paramKnob2 = -(pt.y - _panLast.y) / sz.height;
        
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
