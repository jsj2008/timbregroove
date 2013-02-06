//
//  RecordGesture.m
//  TimbreGroove
//
//  Created by victor on 2/6/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "RecordGesture.h"
#import <UIKit/UIGestureRecognizerSubclass.h>
#import "Global.h"

@interface RecordGesture () {
    NSMutableArray * _receivers;
    bool _initNotified;
}
@end

@implementation RecordGesture

-(id)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if( self )
    {
        _recorder = [PointRecorder new];
        _receivers = [NSMutableArray new];
        
        [[Global sharedInstance] addObserver:self
                                  forKeyPath:@"recording"
                                     options:NSKeyValueObservingOptionNew
                                     context:NULL];
    }
    return self;
    
}
-(void)addReceiver:(id<RecordGestureReceiver>)receiver
{
    [_receivers addObject:receiver];
}

-(void)removeReceiver:(id)receiver
{
    [_receivers removeObject:receiver];
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if( [keyPath isEqualToString:@"recording"] )
    {
        _recording = [Global sharedInstance].recording;
        if( _recording )
        {
            [_recorder reset];
        }
        else
        {
            if( self.state == UIGestureRecognizerStatePossible )
                self.state = UIGestureRecognizerStateFailed;
        }
    }
}

/*
 
 – ignoreTouch:forEvent:
 – canBePreventedByGestureRecognizer:
 – canPreventGestureRecognizer:
*/

-(void)reset
{
    [super reset];
    [_recorder reset]; // um, sure??? 
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _initNotified = false;
    if( self.state == UIGestureRecognizerStatePossible )
    {
        if( ![Global sharedInstance].recording )
        {
            self.state = UIGestureRecognizerStateFailed;
        }
    }
    [super touchesBegan:touches withEvent:event];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if( ![Global sharedInstance].recording )
    {
        self.state = UIGestureRecognizerStateFailed;
    }
    
    [super touchesMoved:touches withEvent:event];
    
    if( self.state == UIGestureRecognizerStateChanged )
    {
        if( !_initNotified )
        {
            for( id<RecordGestureReceiver> rgr in _receivers )
                [rgr RecordGesture:self recordingBegin:_recorder];
            _initNotified = true;
        }
        CGPoint pt = [self translationInView:self.view];
        CGSize sz = self.view.frame.size;
        pt.x /= sz.width;
        pt.y /= sz.height;
        [_recorder add:pt];
        for( id<RecordGestureReceiver> rgr in _receivers )
            [rgr RecordGesture:self recordedPt:(GLKVector3){ pt.x, pt.y, 0 }];
    }
    
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    bool wasRecording = [Global sharedInstance].recording;
    if( wasRecording )
        [Global sharedInstance].recording = false;
    [super touchesEnded:touches withEvent:event];
    if( wasRecording && self.state == UIGestureRecognizerStateEnded )
    {
        for( id<RecordGestureReceiver> rgr in _receivers )
            [rgr RecordGesture:self recordingDone:_recorder];
    }
}


@end
