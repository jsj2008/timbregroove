//
//  EQPanel.h
//  TimbreGroove
//
//  Created by victor on 2/14/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Generic.h"
#import "Mixer+Parameters.h"

#ifndef NO_EQPANEL_DECLS
extern NSString const * kParamCurveShape;
extern NSString const * kParamCurveWidth;
#endif

typedef enum BezShapes {
    kBezShape_NONE = kEQDisabled,
    kBezShape_LowPassRes = kEQLow,
    kBezShape_Parametric = kEQMid,
    kBezShape_HiPassRes = kEQHigh
} BezShapes;



@interface EQPanel : Generic
@property (nonatomic) BezShapes shapeDisplay;
@property (nonatomic) BezShapes shapeEdit;
@end
