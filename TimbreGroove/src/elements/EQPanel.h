//
//  EQPanel.h
//  TimbreGroove
//
//  Created by victor on 2/14/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Painter.h"

typedef enum EQband {
    eqbNone,
    eqbLow,
    eqbMid,
    eqbHigh
} EQBand;

@interface EQPanel : Painter
@property (nonatomic) int band; 
@end
