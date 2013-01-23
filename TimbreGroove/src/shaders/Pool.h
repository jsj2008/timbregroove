//
//  Cloud.h
//  TimbreGroove
//
//  Created by victor on 1/19/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Shader.h"

typedef enum PoolVariables {
    pool_position,
    pool_normal,
    pool_uv,
    POOL_LAST_ATTR = pool_uv,
    pool_pvm,
    pool_mvm,
    pool_normalMat,
    pool_specColor,
    pool_shininess, // specExponent
    pool_sampler,
    pool_lightPos, // vec4
    pool_time,
    POOL_NUM_NAMES
} PoolVariables;

@interface Pool : Shader

@property (nonatomic) GLKVector3 lightPos;

@end
