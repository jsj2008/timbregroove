//
//  PoolWater.m
//  TimbreGroove
//
//  Created by victor on 1/28/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "PoolWater.h"

const char * _pw_names[] = {
    "a_position",
    "a_uvs",
    "u_texture",
    "u_time",
    "u_rippleSize",
    "u_turbulence",
    "u_center",
    "u_radius",
    "u_scale"
};

const char * _pw_shader_name = "PoolScreen";

@implementation PoolWaterShader

-(id)init
{
    self = [super initWithVertex:_pw_shader_name
                     andFragment:_pw_shader_name
                     andVarNames:_pw_names
                     andNumNames:PW_NUM_NAMES
                     andLastAttr:PW_LAST_ATTR
                      andHeaders:nil];
    if( self )
    {
        _rippleSize = 7.0;
        _turbulence = 0.005f;
        _radius = 0.01;
        CGSize sz = [UIScreen mainScreen].bounds.size;
        _scale = (GLKVector2){ 1/sz.width, 1/sz.height };
    }
    return self;
}

-(void)writeStatics
{
    [self writeToLocation:pw_ripple     type:TG_FLOAT   data:&_rippleSize];
    [self writeToLocation:pw_turbulence type:TG_FLOAT   data:&_turbulence];
    [self writeToLocation:pw_scale      type:TG_VECTOR2 data:&_scale];
}

-(void)setCenter:(GLKVector2)center
{
    _center = center;
    [self writeToLocation:pw_center type:TG_VECTOR2 data:&_center];
}

-(void)setRadius:(float)radius
{
    _radius = radius;
    [self writeToLocation:pw_radius type:TG_FLOAT data:&_radius];
}

-(void)setTime:(float)time
{
    _time = time;
    [self writeToLocation:pw_time type:TG_FLOAT data:&time];
}
@end
