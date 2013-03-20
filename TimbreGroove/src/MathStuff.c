//
//  MathStuff.c
//  TimbreGroove
//
//  Created by victor on 3/12/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#include <math.h>

float _explodeFromCenter(float f, float minRange, float maxRange, float bendFactor)
{
    if( f < minRange )
        f = minRange;
    if( f > maxRange )
        f = maxRange;
    f = ( (f-minRange) / ((maxRange-minRange)*0.5)) - 1.0;
    if( !bendFactor )
        bendFactor = 1;
    return (f + (f * bendFactor * expf(-f*f)));
}
