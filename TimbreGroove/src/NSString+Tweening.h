//
//  NSString+Tweening.h
//  TimbreGroove
//
//  Created by victor on 3/7/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>


#import "Tween.h"

@interface NSString (Tweening)
-(NSString *)stringByAppendingTween:(TweenFunction)func len:(NSTimeInterval)len;
@end
