//
//  MenuView.h
//  TimbreGroove
//
//  Created by victor on 12/18/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface MenuView : GLKView
@property bool visible;
- (void)setupGL;
- (void)update:(NSTimeInterval)dt;
- (void)show;
- (void)hide;
- (void)onTap:(UITapGestureRecognizer *)tgr;
@end
