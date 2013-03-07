//
//  Block.h
//  TimbreGroove
//
//  Created by victor on 3/4/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#ifndef TimbreGroove_Block_h
#define TimbreGroove_Block_h

#import <objc/runtime.h>

#define TGC_SIZE  'z'
#define TGC_POINT 'p'
#define TGC_RECT  't'

char GetBlockArgumentType(id block);

#endif
