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
    FMOD::Sound *   _sound;
    FMOD::Channel * _channel;
}
@end


@implementation Sound

-(id)initWithFile:(const char *)fileName soundMan:(SoundMan*)soundMan
{
    if( (self = [super init]) )
    {
        FMOD_RESULT   result;
        FMOD::System * system = (FMOD::System *)[soundMan getSystem];
        bool loop = true;
        
        NSString * path = [[NSBundle mainBundle] resourcePath];
        NSString * fpath = [NSString stringWithFormat:@"%@/%s", path, fileName];
        
        result = system->createSound([fpath UTF8String], FMOD_SOFTWARE, NULL, &_sound);
        ERRCHECK(result);
        
        if( loop )
        {
            result = _sound->setMode(FMOD_LOOP_NORMAL);    /* file can have embedded loop points which automatically makes looping turn on, */
            ERRCHECK(result);
        }
        
        result = system->playSound(FMOD_CHANNEL_FREE, _sound, true, &_channel);
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
    FMOD_RESULT result = _channel->getVolume(&v);
    ERRCHECK(result);
    return v;
}
-(void)setVolume:(float)volume
{
    FMOD_RESULT result = _channel->setVolume(volume);
    ERRCHECK(result);
}

-(bool)paused
{
    bool isPaused;
    FMOD_RESULT result = _channel->getPaused(&isPaused);
    ERRCHECK(result);
    return isPaused;
}

-(void)setPaused:(bool)paused
{
    FMOD_RESULT result = _channel->setPaused(paused);
    ERRCHECK(result);
}

-(void)pause
{
    self.paused = true;
}

-(void)play
{
    FMOD_RESULT result = _channel->setPaused(false);
    ERRCHECK(result);
}

-(void)mute
{
    FMOD_RESULT result = _channel->setPaused(true);
    ERRCHECK(result);    
}

-(void)rewind
{
    _channel->setPosition(0, FMOD_TIMEUNIT_MS);
}

-(void)releaseResource
{
    _sound->release();
}
@end
