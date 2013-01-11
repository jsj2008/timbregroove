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
#import "SoundMan.h"
#import "Tweener.h"
#import "Tween.h"
#import "SettingsVC.h"
#import "objc/runtime.h"

static NSNumber * _userMuted;

@implementation TrackView (Sound)

-(void)setUserMuted:(bool)userMuted
{
    if( userMuted )
        [self fade];
    
    objc_setAssociatedObject(self, &_userMuted, @(userMuted), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if( !userMuted )
        [self play];
}

-(bool)userMuted
{
    return (bool)[objc_getAssociatedObject(self,&_userMuted) intValue];
}

-(void)debugDump
{
    [[SoundMan sharedInstance] dumpTime];
}

-(void)showAndPlay:(int)side
{
    [self showFromDir:side];
    [self play];
}

-(void)hideAndFade:(int)side
{
    if( !side )
        _visible = false;
    else
        [self hideToDir:side];
    [self fade];
}


- (void)showAndSync:(unsigned int)delay
{
    _visible = true;
    [self sync:delay];
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
    if( !self.userMuted )
    {
        TG3dObject * obj = [_graph firstChild];
        float prevVol = obj.sound.prevVolume;
        if( prevVol )
            obj.sound.volume = prevVol;
        [obj.sound play];
    }
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
