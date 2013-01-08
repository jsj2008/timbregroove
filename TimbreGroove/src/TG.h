//
//  TG.h
//  TG1
//
//  Created by victor on 12/8/12.
//
//

#ifndef TG1_TG_h
#define TG1_TG_h

#import "TGAppEventBus.h"

#define jrandom() ( random() / (float)0x7fffffff )
#define randomf(min, max) (( random() / (float)0x7fffffff ) * (max - min) + min)
#define randomi(min, max) ((int)round(randomf((float)min, (float)max)))

static inline NSMutableDictionary * d( NSDictionary * a )
{
    return [[NSMutableDictionary alloc] initWithDictionary:a];
}

static inline NSMutableArray * a(NSArray *a)
{
    return [[NSMutableArray alloc] initWithArray:a];
}

#endif
