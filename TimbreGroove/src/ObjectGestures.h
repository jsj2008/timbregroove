//
//  ObjectGestures.h
//  TimbreGroove
//
//  Created by victor on 4/7/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MoveGesture : UIPanGestureRecognizer
@property (nonatomic,weak) id targetedObject;
@end
