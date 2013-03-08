//
//  Tween.c
//  TimbreGroove
//
//  Created by victor on 3/4/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#include <math.h>
#include <string.h>
#include "Tween.h"

static char * _tween_names[] = {
    "Linear",
    "EaseInSine",
    "EaseOutSine",
    "EaseInOutSine",
    "EaseInBounce",
    "EaseOutBounce",
    "EaseInThrow",
    "EaseOutThrow",
    "Swell"
};

TweenFunction tweenFuncForString(const char * str)
{
    for( int i = 0; i < sizeof(_tween_names)/sizeof(_tween_names[0]); ++i)
    {
        if( !strcmp(_tween_names[i], str) )
            return i;
    }
    return -1;
}

const char * stringForTweenFunc(TweenFunction func)
{
    return _tween_names[func];
}

static float easeOutThrow( float progression )
{
	float f = 0.2;
	float g = 2 * (1.0 + 2 * f + 2 * sqrt(f * (1 + f)));
	float v0 = sqrt(2 * g * (1 + f));
	
	return v0 * progression - 0.5 * g * progression * progression;
}


static float easeOutBounce(float progression)
{
	// calculted with rebound speed = f * incoming speed
	float f = 0.7;
	float t1 = 1.0 / (2.0*f*f*f + 2.0*f*f + 2.0*f + 1.0);
	float t2 = t1 * (1.0 + 2 * f);
	float t3 = t1 * (1.0 + 2*f + 2*f*f);
    
	float g = 2.0 / (t1*t1);
	
	float v1 = g * t1;
	float v2 = f * v1;
	float v3 = f * v2;
	float v4 = f * v3;
	
	if (progression < t1) {
		return 0.5 * g * progression * progression;
		
	} else if (progression < t2) {
		float dt = progression - t1;
		return 1.0 - (v2 * dt - 0.5 * g * dt * dt);
		
	} else if (progression < t3) {
		float dt = progression - t2;
		return 1.0 - (v3 * dt - 0.5 * g * dt * dt);
		
	} else {
		float dt = progression - t3;
		return 1.0 - (v4 * dt - 0.5 * g * dt * dt);
	}
}

float tweenFunc(TweenFunction func, float progression)
{
    switch (func) {
        case kTweenLinear:
            break;
            
        case kTweenEaseInSine:
            return 1.0 - cos(progression * M_PI / 2.0);
            
        case kTweenEaseOutSine:
            return sin(progression * M_PI / 2.0);
            
        case kTweenEaseInOutSine:
            return 0.5 * (1.0 + sin(1.5 * M_PI + progression * M_PI));
            
        case kTweenEaseOutBounce:
            return easeOutBounce(progression);
            
        case kTweenEaseInBounce:
            return 1.0 - easeOutBounce(1.0 - progression);
            
        case kTweenEaseOutThrow:
            return easeOutThrow(progression);
            
        case kTweenEaseInThrow:
            return 1.0 - easeOutThrow(1.0 - progression);
            
        case kTweenSwell:
            return sin(progression * M_PI);
            
	}
	return progression;
}

