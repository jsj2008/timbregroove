//
//  PoolsideAudio.m
//  TimbreGroove
//
//  Created by victor on 3/13/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Audio.h"
#import "Tween.h"
#import "Names.h"
#import "Scene.h"
#import "TriggerMap.h"

@interface PoolsideAudio : Audio {
    FloatParamBlock _volume;
}

@end

@implementation PoolsideAudio

-(void)start
{
    [super startMidiFile];
    [super start];
}

-(void)triggersChanged:(Scene *)scene
{
    [super triggersChanged:scene];
    
    if( scene )
    {
         TriggerMap * tm = scene.triggers;
        
        FloatParamBlock volTurn = [tm getFloatTrigger:kParamMasterVolume];
        volTurn(0.005);
        volTurn = nil;
        
        _volume = [tm getFloatTrigger:[kParamMasterVolume stringByAppendingTween:kTweenEaseOutSine len:5]
                                   cb:TweenLooper];
        _volume(0.9);
    }
    else
    {
        _volume = nil;
    }
}


@end
