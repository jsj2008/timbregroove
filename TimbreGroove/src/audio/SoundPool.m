//
//  SoundPool.m
//  TimbreGroove
//
//  Created by victor on 1/7/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "SoundPool.h"
#import "Sound.h"
#import "SoundMan.h"

@class Sound;

static SoundPool *__spf;

@interface SoundPool() {
    SoundMan * _soundMan;
    
}
@end

@implementation SoundPool

+(id)sharedInstance
{
    if( !__spf )
        __spf = [SoundPool new];
    return __spf;
}

-(Sound*)getSound:(NSDictionary *)params
{
    if( !_soundMan )
        _soundMan = [SoundMan sharedInstance];
    
    static int currSound;
    static const char * sounds[3] = {
        "TG1Band-perc-24k.aif",
        "TG1Band-pitched-24k.aif",
        "TGAmb3-32k.aif"
    };
    
    Sound * sound = [_soundMan getSound:sounds[currSound]];
    currSound = (currSound + 1) % 3;
    return sound;
}

@end
