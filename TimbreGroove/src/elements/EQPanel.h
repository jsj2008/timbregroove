//
//  EQPanel.h
//  TimbreGroove
//
//  Created by victor on 2/14/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Generic.h"

typedef enum BezShapes {
    kBezShape_Parametric,
    kBezShape_LowPassRes,
    kBezShape_HiPassRes
} BezShapes;



@interface EQPanel : Generic
@property (nonatomic) BezShapes shapeDisplay;
@property (nonatomic) BezShapes shapeEdit;
@end
