//
//  MathStuff.c
//  TimbreGroove
//
//  Created by victor on 3/12/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#include <math.h>

float _explodeFromCenter(float f, float minRange, float maxRange)
{
    f = ( f / ((maxRange-minRange)*0.5)) - 1.0;
    return (f + (f * expf(-f*f)));
}
