//
//  View.h
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "Graph.h"

@class RecordGesture;
@class TapRecordGesture;

@interface GraphView : GLKView {
@private // here for categories
    bool    _panTracking;
    CGPoint _panLast;
    RecordGesture * _recordGesture;
    TapRecordGesture * _tapRecordGesture;
}
@property (nonatomic) GLKVector4 backcolor;
@property (nonatomic,strong) Graph * graph;

-(void)update:(NSTimeInterval)dt;
-(void)render;

-(void)commitSettings;
@end
