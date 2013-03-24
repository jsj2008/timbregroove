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
@class Parameter;

@interface GraphView : GLKView {
@private // here for categories
    bool    _objectResponded;
    CGPoint _panLast;
    NSMutableArray * _triggerStack;
    ViewTriggers * _currentTriggers;
    id _targetedObject;
}
@property (nonatomic) GLKVector4 backcolor;
@property (nonatomic,strong) Graph * graph;
@property (nonatomic,weak)   Scene * scene;

-(void)update:(NSTimeInterval)dt;
-(void)render;
-(void)graphChanged;

-(void)commitSettings;
@end

@interface GraphView (Touches)
-(void)setupTouches;
-(void)triggersChanged:(Scene *)scene;
-(void)pushTriggers;
-(void)popTriggers;
-(Parameter *)paramWrapperForObject:(TG3dObject *)targetObject parameter:(Parameter *)parameterToWrap;
@end

