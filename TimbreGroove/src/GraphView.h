//
//  View.h
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "Graph.h"

@class Scene;
@class ViewTriggers;

@interface GraphView : GLKView {
@private // here for categories
    bool    _panTracking;
    CGPoint _panLast;
    NSMutableArray * _triggerStack;
    ViewTriggers * _currentTriggers;
}
@property (nonatomic) GLKVector4 backcolor;
@property (nonatomic,strong) Graph * graph;
@property (nonatomic,weak)   Scene * scene;

-(void)update:(NSTimeInterval)dt;
-(void)render;
-(void)graphChanged;

-(void)commitSettings;
@end
