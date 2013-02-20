//
//  TGCapture.h
//  TimbreGroove
//
//  Created by victor on 12/18/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TG3dObject;

@interface EventCapture : NSObject
-(id)childElementOf:(TG3dObject *)graph
       fromScreenPt:(CGPoint)pt
             inView:(UIView *)view;

+(id)getGraphViewTapChildElementOf:(TG3dObject *)root;
@end
