//
//  TrackView+Sound.m
//  TimbreGroove
//
//  Created by victor on 12/24/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TrackView+Sound.h"
#import "TG3dObject+Sound.h"
#import "Sound.h"
#import "Tweener.h"
#import "Tween.h"

@implementation TrackView (Sound)

-(void)showAndPlay:(int)side
{
    [self showFromDir:side];
    [self play];
}

-(void)hideAndFade:(int)side
{
    [self hideToDir:side];
    [self fade];
}

- (void)showSceneAndPlay
{
    [self showScene];
    [self play];
}

- (void)showSceneAndSync:(unsigned int)delay
{
    [self showScene];
    [self sync:delay];
}

- (void)hideSceneAndFade
{
    [self hideScene];
    [self fade];
}

- (void)sync:(unsigned int)delay
{
    TG3dObject * obj = _graph.children[0];
    [obj.sound rewind];
    [obj.sound sync:delay];
    [self play];
}

-(void)play
{
    TG3dObject * obj = _graph.children[0];
    float prevVol = obj.sound.prevVolume;
    if( prevVol )
        obj.sound.volume = prevVol;
    [obj.sound play];
}

-(void)fade
{
    TG3dObject * obj = _graph.children[0];
    obj.sound.prevVolume = obj.sound.volume;

    NSDictionary * params = @{  TWEEN_DURATION: @0.7f,
                        TWEEN_TRANSITION: TWEEN_FUNC_EASEOUTSINE,
                                    @"volume":@0,
                                TWEEN_ON_COMPLETE_SELECTOR: @"mute",
                                TWEEN_ON_COMPLETE_TARGET: obj.sound
    };
    
    [Tweener addTween:obj.sound withParameters:params];
}

@end
