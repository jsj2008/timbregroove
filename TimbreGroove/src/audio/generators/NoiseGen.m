//
//  NoiseGen.m
//  TimbreGroove
//
//  Created by Victor Stone on 6/18/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "NoiseGen.h"
#import "TGTypes.h"

void initNoise(NoiseGen *ng)
{
    ng->max_key = 0x1f; // Five bits set
    ng->range = 127;
    ng->key = 0;
    for (int i = 0; i < 5; i++)
        ng->white_values[i] = R0_n(10000) % (ng->range/5);
}

float nextNoiseValue(NoiseGen * ng)
{
    int last_key = ng->key;
    UInt32 sum;
    
    ng->key++;
    if (ng->key > ng->max_key)
        ng->key = 0;
    int diff = last_key ^ ng->key;
    sum = 0;
    for (int i = 0; i < 5; i++)
    {
        if (diff & (1 << i))
            ng->white_values[i] = R0_n(10000) % (ng->range/5);
        sum += ng->white_values[i];
    }
    return (float)sum / ((float)ng->range * 0.5) - 1.0;
}
