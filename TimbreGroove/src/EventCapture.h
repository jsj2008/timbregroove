//
//  TGCapture.h
//  TimbreGroove
//
//  Created by victor on 12/18/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Node3d;

typedef void (^CaptureRecurseBlock)(Node3d *);

@interface EventCapture : NSObject
+(id)getGraphViewTapChildElementOf:(Node3d *)root
                            inView:(UIView *)view
                              atPt:(CGPoint)pt;

@end
