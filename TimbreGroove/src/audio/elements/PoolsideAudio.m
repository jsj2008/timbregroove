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
    FloatParamBlock _channelVolume;
    FloatParamBlock _channelVolumeAnimated;
}

@end

@implementation PoolsideAudio

-(void)start
{
    [super startMidiFile];
    [super start];
    
    _channelVolume(0.2);         // <-- start here
    _channelVolumeAnimated(1.0); // <-- animate to here, then loop
    
}

-(void)triggersChanged:(Scene *)scene
{
    [super triggersChanged:scene];
    
    if( scene )
    {
         TriggerMap * tm = scene.triggers;
        
        _channelVolume = [tm getFloatTrigger:kParamChannelVolume];
        _channelVolumeAnimated = [tm getFloatTrigger:[kParamChannelVolume stringByAppendingTween:kTweenEaseOutSine len:5]
                                   cb:TweenReverseLooper];
    }
    else
    {
        _channelVolume = nil;
        _channelVolumeAnimated = nil;
    }
}


@end
