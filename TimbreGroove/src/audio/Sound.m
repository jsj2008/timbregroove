//
//  Sound.m
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Sound.h"
#import "SoundMan.h"
#import "fmod_helper.h"

@interface Sound () {
    FMOD_SOUND *   _sound;
    FMOD_CHANNEL * _channel;
}
@end


@implementation Sound

-(id)initWithFile:(const char *)fileName soundMan:(SoundMan*)soundMan
{
    if( (self = [super init]) )
    {
        FMOD_RESULT   result;
        FMOD_SYSTEM * system = (FMOD_SYSTEM *)[soundMan getSystem];
        bool loop = true;
        
        NSString * path = [[NSBundle mainBundle] resourcePath];
        NSString * fpath = [NSString stringWithFormat:@"%@/%s", path, fileName];
        
        result = FMOD_System_CreateSound(system, [fpath UTF8String], FMOD_SOFTWARE, NULL, &_sound);
        ERRCHECK(result);
        
        if( loop )
        {
            result = FMOD_Sound_SetMode(_sound, FMOD_LOOP_NORMAL);    /* file can have embedded loop points which automatically makes looping turn on, */
            ERRCHECK(result);
        }
        
        result = FMOD_System_PlaySound(system, FMOD_CHANNEL_FREE, _sound, true, &_channel);
        ERRCHECK(result);

        /*
        result = channel->setUserData((__bridge void *)self);
        ERRCHECK(result);
         */
    }
    
    return self;
}

-(float)volume
{
    float v;
    FMOD_RESULT result = FMOD_Channel_GetVolume(_channel,&v);
    ERRCHECK(result);
    return v;
}
-(void)setVolume:(float)volume
{
    FMOD_RESULT result = FMOD_Channel_SetVolume(_channel,volume);
    ERRCHECK(result);
}

-(bool)paused
{
    FMOD_BOOL isPaused;
    FMOD_RESULT result = FMOD_Channel_GetPaused(_channel,&isPaused);
    ERRCHECK(result);
    return (bool)isPaused;
}

-(void)setPaused:(bool)paused
{
    FMOD_RESULT result = FMOD_Channel_SetPaused(_channel,paused);
    ERRCHECK(result);
}

-(void)pause
{
    self.paused = true;
}

-(void)play
{
    self.paused = false;
}

-(void)mute
{
    self.paused = true;
}

-(void)rewind
{
    FMOD_RESULT result = FMOD_Channel_SetPosition(_channel, 0, FMOD_TIMEUNIT_MS);
    ERRCHECK(result);
}

-(void)releaseResource
{
    FMOD_Sound_Release(_sound);
}
-(void)sync:(int)delay
{
    FMOD_RESULT result;
    unsigned int delayhi, delaylo;
    result = FMOD_Channel_GetDelay(_channel, FMOD_DELAYTYPE_DSPCLOCK_START, &delayhi, &delaylo);
    ERRCHECK(result);
    NSLog(@"Delay hi: %d / lo: %d",delayhi, delaylo);
    /*
    FMOD_64BIT_ADD( delayhi, delaylo, 0, delay );
    result = FMOD_Channel_SetDelay(_channel, FMOD_DELAYTYPE_DSPCLOCK_START, delayhi, delaylo);
    ERRCHECK(result);
     */
    
}
@end
