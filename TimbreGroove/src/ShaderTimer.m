//
//  ShaderTimer.m
//  TimbreGroove
//
//  Created by victor on 4/18/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "ShaderTimer.h"

@implementation ShaderTimer

-(void)getShaderFeatureNames:(NSMutableArray *)putHere
{
    [putHere addObject:kShaderFeatureTime];
}

-(void)bind:(Shader *)shader object:(Painter *)object
{    
    ShaderTimeType stt = _timerType;
    if( stt > kSTT_Custom )
    {
        float time;
        if( stt == kSTT_Timer )
            time = object.timer;
        else if( stt == kSTT_CountDown)
        {
            float countDown = _countDownBase - object.timer;
            if( countDown < 0.0 )
                return; // N.B. <-----------------
            time = countDown;
        }
        else
            time = object.totalTime;
        [shader writeToLocation:gv_time type:TG_FLOAT data:&time];
    }
    
}

-(void)unbind:(Shader *)shader {}
@end
