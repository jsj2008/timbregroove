//
//  View.h
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "Graph.h"


@interface GraphView : GLKView {
@private // here for categories
    bool    _panTracking;
    CGPoint _panLast;

    PointParamBlock _triggerDirection;
    FloatParamBlock _triggerPinch;
    PointParamBlock _triggerTapPos;
    PointParamBlock _triggerTap1;
    FloatParamBlock _triggerPanX;
    FloatParamBlock _triggerPanY;
    PointParamBlock _triggerDrag1;
    PointParamBlock _triggerDragPos;
}
@property (nonatomic) GLKVector4 backcolor;
@property (nonatomic,strong) Graph * graph;

-(void)update:(NSTimeInterval)dt;
-(void)render;

-(void)commitSettings;
@end
