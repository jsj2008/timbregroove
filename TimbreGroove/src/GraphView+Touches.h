//
//  GraphView+Touches.h
//  TimbreGroove
//
//  Created by victor on 2/19/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "GraphView.h"

@class Scene;

@interface GraphView (Touches)
-(void)setupTouches;
-(void)triggersChanged:(Scene *)scene;
-(void)pushTriggers;
-(void)popTriggers;
@end
