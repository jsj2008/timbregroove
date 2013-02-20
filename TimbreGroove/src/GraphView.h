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

-(void)watchForGlobals:(NSDictionary *)lookups;
-(void)update:(NSTimeInterval)dt mixerUpdate:(MixerUpdate *)mixerUpdate;
-(void)render;
-(NSArray *)getSettings;
-(void)commitSettings;
@end
