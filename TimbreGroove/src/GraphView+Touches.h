//
//  GraphView+Touches.h
//  TimbreGroove
//
//  Created by victor on 2/19/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "GraphView.h"

@class RecordGesture;
@class TapRecordGesture;

@interface GraphView (Touches)
-(void)setupTouches;

@property (nonatomic,strong) RecordGesture * recordGesture;
@property (nonatomic,strong) TapRecordGesture * tapRecordGesture;

@end
