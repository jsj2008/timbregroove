//
//  NSString+Tweening.m
//  TimbreGroove
//
//  Created by victor on 3/7/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "NSString+Tweening.h"

@implementation NSString (Tweening)

-(NSString *)stringByAppendingTween:(TweenFunction)func len:(NSTimeInterval)len
{
    return [self stringByAppendingFormat:@":%s:%f",stringForTweenFunc(func),len ];
}
@end
