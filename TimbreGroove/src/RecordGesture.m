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
    PointRecorder * _recorder;
    PointRecorder * _snapshot;
}
@end

@implementation RecordGesture

-(id)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if( self )
    {
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
            _snapshot = _recorder;
            _recorder = [PointRecorder new];
            for( id<RecordGestureReceiver> rgr in _receivers )
                [rgr RecordGesture:self recordingWillBegin:_recorder];            
        }
        else
        {
            if( self.state == UIGestureRecognizerStatePossible )
                self.state = UIGestureRecognizerStateFailed;
            if( _recorder.count )
                for( id<RecordGestureReceiver> rgr in _receivers )
                    [rgr RecordGesture:self recordingDone:_recorder];
            
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
                [rgr RecordGesture:self recordingBegan:_recorder];
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
    {
        if( _recorder.count )
        {
            [Global sharedInstance].recording = false;
        }
        else
        {
            // The user did not record motion, probably taps
            // or other gestures. Just restore the previous
            // player
            if( _snapshot )
            {
                _recorder = _snapshot;
                _snapshot = nil;
            }
            self.state = UIGestureRecognizerStateCancelled;
        }
    }
    [super touchesEnded:touches withEvent:event];
    if( wasRecording && self.state == UIGestureRecognizerStateEnded )
    {
        for( id<RecordGestureReceiver> rgr in _receivers )
            [rgr RecordGesture:self recordingDone:_recorder];
    }
}


@end

//=========================================================================

@interface TapRecordGesture () {
    NSMutableArray * _receivers;
    PointRecorder * _recorder;
    PointRecorder * _snapshot;
}
@end

@implementation TapRecordGesture

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
-(void)addReceiver:(id<TapRecordGestureReceiver>)receiver
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
            _snapshot = _recorder;
            _recorder = [PointRecorder new];
            for( id<TapRecordGestureReceiver> rgr in _receivers )
                [rgr TapRecordGesture:self recordingWillBegin:_recorder];
            
            for( id<TapRecordGestureReceiver> rgr in _receivers )
                [rgr TapRecordGesture:self recordingBegan:_recorder];
            
        }
        else
        {
            if( !_recorder.count && _snapshot )
            {
                // user didn't record anything here, probably pans
                // or other gestures instead. Use the previous
                // recording
                _recorder = _snapshot;
                _snapshot = nil; // no reason to hold on to the reference
            }
            for( id<TapRecordGestureReceiver> rgr in _receivers )
                [rgr TapRecordGesture:self recordingDone:_recorder];
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
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if( self.state == UIGestureRecognizerStatePossible && ![Global sharedInstance].recording)
    {
        self.state = UIGestureRecognizerStateFailed;
    }
    [super touchesBegan:touches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    if( [Global sharedInstance].recording && self.state == UIGestureRecognizerStateEnded )
    {
        CGPoint pt = [self locationInView:self.view];
        CGSize sz = self.view.frame.size;
        pt.x /= sz.width;
        pt.y /= sz.height;
        [_recorder add:pt];
        for( id<TapRecordGestureReceiver> rgr in _receivers )
            [rgr TapRecordGesture:self recordedPt:(GLKVector3){ pt.x, pt.y, 0 }];
    }
}

@end

//=========================================================================

@implementation MenuInvokeGesture

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if( [Global sharedInstance].recording )
    {
        self.state = UIGestureRecognizerStateFailed;
    }
    [super touchesBegan:touches withEvent:event];
}

@end