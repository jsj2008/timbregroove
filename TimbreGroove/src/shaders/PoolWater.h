//
//  PoolWater.h
//  TimbreGroove
//
//  Created by victor on 1/28/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Shader.h"


typedef enum PoolWaterVariables {
    pw_position,
    pw_uv,
    PW_LAST_ATTR = pw_uv,
    //    pw_pvm,
    pw_sampler,
    pw_time,
    pw_ripple,
    pw_turbulence,
    pw_center,
    pw_radius,
    pw_scale,
    PW_NUM_NAMES
} PoolWaterVariables;

@interface PoolWaterShader : Shader
@property (nonatomic) float rippleSize;
@property (nonatomic) float turbulence;
@property (nonatomic) GLKVector2 center;
@property (nonatomic) float radius;
@property (nonatomic) GLKVector2 scale;
@property (nonatomic) float time;
-(void)writeStaticsWithW:(float)w H:(float)h;
@end
