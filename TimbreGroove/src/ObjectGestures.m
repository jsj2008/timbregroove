//
//  ObjectGestures.m
//  TimbreGroove
//
//  Created by victor on 4/7/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "ObjectGestures.h"
#import <UIKit/UIGestureRecognizerSubclass.h>
#import "EventCapture.h"
#import "GraphView.h"

@implementation MoveGesture

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if( self.state == UIGestureRecognizerStatePossible )
    {
        UITouch * touch = [touches anyObject];
        GraphView * view = (GraphView *)self.view;
        CGPoint pt = [touch locationInView:view];
        _targetedObject = [EventCapture getGraphViewTapChildElementOf:view.graph inView:view atPt:pt];
        if( !_targetedObject )
        {
            self.state = UIGestureRecognizerStateFailed;
            return;
        }
    }
    [super touchesBegan:touches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    _targetedObject = nil;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}
@end
