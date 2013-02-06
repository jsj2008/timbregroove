//
//  RecordGesture.h
//  TimbreGroove
//
//  Created by victor on 2/6/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PointRecorder.h"

@class RecordGesture;

@protocol RecordGestureReceiver <NSObject>
-(void)RecordGesture:(RecordGesture*)rg recordingBegin:(PointRecorder *)recorder;
-(void)RecordGesture:(RecordGesture*)rg recordedPt:(GLKVector3)pt;
-(void)RecordGesture:(RecordGesture*)rg recordingDone:(PointRecorder *)recorder;
@end

@interface RecordGesture : UIPanGestureRecognizer
-(void)addReceiver:(id<RecordGestureReceiver>)receiver;
-(void)removeReceiver:(id)receiver;
@property (nonatomic,readonly) PointRecorder * recorder;
@property (nonatomic) bool recording;
@end
