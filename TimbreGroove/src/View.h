//
//  View.h
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "Graph.h"

@interface View : GLKView {
    @protected
    Graph * _graph;
    bool _visible;
    GLKVector4 _backcolor;
}
@property (nonatomic,readonly) bool visible;
@property (nonatomic) float x;
@property (nonatomic) float y;
@property (nonatomic) float width;
@property (nonatomic) float height;
@property (nonatomic,strong) Graph * graph;
-(void)animateProp:(const char *)propName targetVal:(float)targetVal hide:(bool)hide;
-(void)showScene;
-(void)hideScene;
-(void)update:(NSTimeInterval)dt;
-(void)drawRect:(CGRect)rect;
-(void)setupGL;

@end
