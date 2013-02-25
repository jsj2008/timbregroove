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
    Instrument * _instrument;
}

@end
@implementation Audio
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
    ConfigInstrument * instrumentConfig = config.instrument;
    if( instrumentConfig )
    {
        Instrument * instrument = [_mixer loadInstrumentFromConfig:instrumentConfig];
        if( instrument )
        {
            _instrument = instrument;
            _midiFile = config.midiFile;
        }
    }
}

-(void)start
{
    if( _midiFile )
        [_mixer playMidiFile:_midiFile withInstrument:_instrument];
    _instrument = nil;
    
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
