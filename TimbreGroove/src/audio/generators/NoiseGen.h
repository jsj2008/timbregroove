//
//  NoiseGen.h
//  TimbreGroove
//
//  Created by Victor Stone on 6/18/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct _NoiseGen
{
    int max_key;
    int key;
    unsigned int white_values[5];
    unsigned int range;
} NoiseGen;

void initNoise(NoiseGen *ng);
float nextNoiseValue(NoiseGen * ng);
