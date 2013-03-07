//
//  Tween.h
//  TimbreGroove
//
//  Created by victor on 3/4/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#ifndef TimbreGroove_Tween_h
#define TimbreGroove_Tween_h

typedef enum TweenFunction {
    kTweenLinear,
    kTweenEaseInSine,
    kTweenEaseOutSine,
    kTweenEaseInOutSine,
    kTweenEaseInBounce,
    kTweenEaseOutBounce,
    kTweenEaseInThrow,
    kTweenEaseOutThrow
} TweenFunction;

float tweenFunc(TweenFunction func, float progression);
TweenFunction funcForString(const char * str);
#endif
