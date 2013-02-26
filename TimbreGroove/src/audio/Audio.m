//
//  Audio.m
//  TimbreGroove
//
//  Created by victor on 2/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Audio.h"
#import "Mixer.h"
#import "Mixer+Midi.h"
#import "Config.h"

@interface Audio () {
    Mixer * _mixer;
    NSString * _midiFile;
}

@end
@implementation Audio

+(id)audioFromConfig:(ConfigAudioProfile *)config
{
    Class klass = NSClassFromString(config.instanceClass);
    Audio * audio = [klass new];
    [audio loadAudioFromConfig:config];
    return audio;
}

- (id)init
{
    self = [super init];
    if (self) {
        _mixer = [Mixer sharedInstance];
    }
    return self;
}

-(void)loadAudioFromConfig:(ConfigAudioProfile *)config
{
    NSDictionary * instrumentConfigs = config.instruments;
    _instruments = [NSMutableDictionary new];
    for( NSString * name in instrumentConfigs )
        _instruments[name] = [_mixer loadInstrumentFromConfig:instrumentConfigs[name]];
    _midiFile = config.midiFile;
}

-(void)start
{
    if( _midiFile )
    {
        //[_mixer playMidiFile:_midiFile withInstrument:];
    }
}

-(void)update:(NSTimeInterval)dt mixerUpdate:(MixerUpdate *)mixerUpdate
{
    [_mixer update:mixerUpdate];
}

-(NSDictionary *)getParameters
{
    return [_mixer getParameters];
}
@end
