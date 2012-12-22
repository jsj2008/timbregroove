//
//  TrackView.m
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TrackView.h"
#import "Graph.h"
#import "Camera.h"
#import "TGiTweener.h"
#import "TGiTween.h"

@implementation TrackView

-(void)setupGL
{
    [super setupGL];
    GLKVector3 pos = { 0, 0, -5 }; //CAMERA_DEFAULT_Z };
    _graph.camera.position = pos;
    _backcolor = GLKVector4Make(0.1, 0.1, 0.1, 1);
}

- (void)showFromDir:(int)dir
{
    _visible = true;
    
    CGRect rc = self.frame;
    rc.origin.x = rc.size.width * dir;
    self.frame = rc;
    NSDictionary * params = @{  TWEEN_DURATION: @0.7f,
                                TWEEN_TRANSITION: TWEEN_FUNC_EASEOUTSINE,
                                            @"x": @(0)
    };
    
    [TGiTweener addTween:self withParameters:params];
}

- (void)hideToDir:(int)dir
{
    CGRect rc = self.frame;
    NSDictionary * params = @{  TWEEN_DURATION: @0.7f,
                              TWEEN_TRANSITION: TWEEN_FUNC_EASEOUTSINE,
                                          @"x": @(rc.size.width*dir),
                    TWEEN_ON_COMPLETE_SELECTOR: @"markHidden",
                      TWEEN_ON_COMPLETE_TARGET: self
    };
    
    [TGiTweener addTween:self withParameters:params];
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
}

-(void)markHidden
{
    _visible = false;
}
@end
