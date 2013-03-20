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
    FloatParamBlock _channelVolumeAnimated;
    int             _ambientChannel;
}

@end

@implementation PoolsideAudio

-(void)loadAudioFromConfig:(ConfigAudioProfile *)config
{
    [super loadAudioFromConfig:config];
    self.channelVolumes = @[ @(0.2) ]; // this gets set every activate
}
-(void)start
{
    [super startMidiFile];
    [super start];
}

-(void)activate
{
    [super activate];
    // our channel is already selected in base class
    _channelVolumeAnimated(0.6); // <-- animate to here, then loop
}

-(void)triggersChanged:(Scene *)scene
{
    [super triggersChanged:scene];
    
    if( scene )
    {
         TriggerMap * tm = scene.triggers;
        
        _channelVolumeAnimated = [tm getFloatTrigger:[kParamChannelVolume stringByAppendingTween:kTweenEaseOutSine len:3.2]
                                   cb:TweenReverseLooper];
    }
    else
    {
        _channelVolumeAnimated = nil;
    }
}


@end
