//
//  SoundMan.m
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "SoundMan.h"
#import "Sound.h"
#import "fmod_helper.h"

@interface SoundMan () {
    FMOD_SYSTEM   *_system;
    
    //FMOD::ChannelGroup * m_bandGroup;
    
    NSMutableArray * _sounds;
    
    
}

@end
@implementation SoundMan

-(Sound *)getSound:(const char *)fileName
{
    Sound * sound = [[Sound alloc] initWithFile:fileName soundMan:self];
    if( !_sounds )
        _sounds = [NSMutableArray new];
    [_sounds addObject:sound];
    return sound;
}

-(void *)getSystem
{
    return _system;
}

-(void)update:(NSTimeInterval)dt
{
    FMOD_RESULT result;
    
    if (_system != NULL)
    {
        /*
        int         channelsplaying;
        result = m_system->getChannelsPlaying(&channelsplaying);
        ERRCHECK(result);
        */
        
        result = FMOD_System_Update(_system); // required for callbacks() to work (and other stuff)
        ERRCHECK(result);
    }
}

-(void)wakeup
{
    FMOD_RESULT   result;
    unsigned int  version;
    /*
     Create a System object and initialize
     */
    result = FMOD_System_Create(&_system);
    ERRCHECK(result);
    
    result = FMOD_System_GetVersion(_system, &version);
    ERRCHECK(result);
    
    if (version < FMOD_VERSION)
    {
        NSLog(@"You are using an old version of FMOD %08x.  This program requires %08x\n", version, FMOD_VERSION);
        exit(-1);
    }
    
    result = FMOD_System_Init(_system, 32, FMOD_INIT_NORMAL | FMOD_INIT_ENABLE_PROFILE, NULL);
    ERRCHECK(result);
}

-(void)goAway
{
    for( Sound * s in _sounds )
    {
        [s releaseResource];
    }
    FMOD_System_Release(_system);
}
@end
