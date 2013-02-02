//
//  View.h
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "Graph.h"


@interface View : GLKView

@property (nonatomic) GLKVector4 backColor;

@property (nonatomic,readonly) id firstNode;
@property (nonatomic,strong) Graph * graph;
@property (nonatomic) bool skipBoilerPlate;

-(void)update:(NSTimeInterval)dt;
-(void)render;

@end
