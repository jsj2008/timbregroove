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
}
@end

@implementation SoundPool

+(id)sharedInstance
{
	@synchronized (self) {
        if( !__spf )
            __spf = [SoundPool new];
    }
    return __spf;
}

-(Sound*)getSound:(NSDictionary *)params
{
    static int currSound;
    static const char * sounds[] = {
        "TGAmb1-32k.aif",
        "TGAmb2-32k.aif",
        "TGAmb3-32k.aif",
        "TG1Band-pitched-24k.aif",
        "TG1Band-perc-24k.aif"
    };
    
    Sound * sound = [[SoundMan sharedInstance] getSound:sounds[currSound]];
    currSound = (currSound + 1) % 5;
    return sound;
}

@end
