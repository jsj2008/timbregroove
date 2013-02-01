//
//  View.h
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "Graph.h"

#define SHOW_DIR_RIGHT 1
#define SHOW_NOW       0
#define HIDE_NOW       0
#define SHOW_DIR_LEFT -1

@class View;

@protocol ViewDelegate <NSObject>
@optional
-(void)tgViewWillAppear:(View *)view;
-(void)tgViewWillDisappear:(View *)view;
-(void)tgViewIsFullyVisible:(View *)view;
-(void)tgViewIsOutofSite:(View *)view;
@end

@interface View : GLKView<ViewDelegate> {
@protected
    GLKVector4 _backcolor;
}
@property (nonatomic,readonly) id firstNode;


@property (nonatomic) float x;
@property (nonatomic) float y;
@property (nonatomic) float width;
@property (nonatomic) float height;
@property (nonatomic,strong) Graph * graph;

@property (nonatomic) CGRect desiredFrame;
@property (nonatomic) bool markedForDelete;

-(void)addDelegate:(id<ViewDelegate>)delegate;

-(void)shrinkToNothing;
-(void)showFromDir:(int)dir;
-(void)hideToDir:(int)dir;

-(void)update:(NSTimeInterval)dt;
-(void)setupGL;

@end
