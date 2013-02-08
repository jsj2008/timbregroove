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
@class TapRecordGesture;


@protocol RecordGestureReceiver <NSObject>
-(void)RecordGesture:(RecordGesture*)rg recordingWillBegin:(PointRecorder *)recorder;
-(void)RecordGesture:(RecordGesture*)rg recordingBegan:(PointRecorder *)recorder;
-(void)RecordGesture:(RecordGesture*)rg recordedPt:(GLKVector3)pt;
-(void)RecordGesture:(RecordGesture*)rg recordingDone:(PointRecorder *)recorder;
@end

@protocol TapRecordGestureReceiver <NSObject>
-(void)TapRecordGesture:(TapRecordGesture*)rg recordingWillBegin:(PointRecorder *)recorder;
-(void)TapRecordGesture:(TapRecordGesture*)rg recordingBegan:(PointRecorder *)recorder;
-(void)TapRecordGesture:(TapRecordGesture*)rg recordedPt:(GLKVector3)pt;
-(void)TapRecordGesture:(TapRecordGesture*)rg recordingDone:(PointRecorder *)recorder;
@end

@interface RecordGesture : UIPanGestureRecognizer
-(void)addReceiver:(id<RecordGestureReceiver>)receiver;
-(void)removeReceiver:(id)receiver;
@property (nonatomic) bool recording;
@end

@interface TapRecordGesture : UITapGestureRecognizer
-(void)addReceiver:(id<TapRecordGestureReceiver>)receiver;
-(void)removeReceiver:(id)receiver;
@property (nonatomic) bool recording;
@end

@interface MenuInvokeGesture : UITapGestureRecognizer

@end
