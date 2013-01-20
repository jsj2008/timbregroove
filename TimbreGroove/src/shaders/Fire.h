//
//  Fire.h
//  TimbreGroove
//
//  Created by victor on 1/19/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Shader.h"

typedef enum FireVariables {
    fv_position,
    fv_normal,
    FV_LAST_ATTR = fv_normal,
    fv_pvm,
    fv_mvm,
    fv_normalMat,
    fv_time,
    FV_NUM_NAMES
} FireVariables;

@interface Fire : Shader


@end
