//
//  Cloud.h
//  TimbreGroove
//
//  Created by victor on 1/19/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Shader.h"

typedef enum CloudVariables {
    cld_position,
    cld_normal,
    CLD_LAST_ATTR = cld_normal,
    cld_pvm,
    cld_mvm,
    cld_normalMat,
    cld_time,
    CLD_NUM_NAMES
} CloudVariables;

@interface Cloud : Shader

@end
