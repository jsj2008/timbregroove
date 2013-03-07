//
//  Audio.m
//  TimbreGroove
//
//  Created by victor on 2/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Audio.h"
#import "SoundSystem.h"
#import "Midi.h"
#import "SoundSystemParameters.h"
#import "Config.h"
#import "Scene.h"
#import "Names.h"
#import "Instrument.h"

@interface Audio () {
@protected
    SoundSystem *        _soundSystem;
    SoundSystemParameters * _parameters;
    NSString *           _midiFile;
    ConfigAudioProfile * _config;
    Midi *               _midi;
}

@end
@implementation Audio

+(id)audioFromConfig:(ConfigAudioProfile *)config withScene:(Scene *)scene
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
        _soundSystem = [SoundSystem sharedInstance];
        _parameters = [[SoundSystemParameters alloc] initWithSoundSystem:_soundSystem];
    }
    return self;
}

-(void)dealloc
{
    for( Instrument * instrument in [_instruments allValues] )
        [_soundSystem decomissionInstrument:instrument];
    
    NSLog(@"Audio object gone");
}

-(void)loadAudioFromConfig:(ConfigAudioProfile *)config
{
    _instruments = [NSMutableDictionary new];
    [config.instruments each:^(id name, id configInstrument) {
        _instruments[name] = [_soundSystem loadInstrumentFromConfig:configInstrument];
    }];
    _midiFile = config.midiFile;
    _config = config;
}

-(void)start
{
}

-(void)play
{
    [[_instruments allValues] each:^(id instrument) {
        [_soundSystem plugInstrumentIntoBus:instrument];
    }];

    if( _midi )
        [_midi resume];
}

-(void)pause
{
    if( _midi )
        [_midi pause];
    
    [[_instruments allValues] each:^(id instrument) {
        [_soundSystem unplugInstrumentFromBus:instrument];
    }];
}

-(void)update:(NSTimeInterval)dt
{
    [_soundSystem update:dt];
    [_parameters update:dt];
    [_midi update:dt];
}

-(void)triggersChanged:(Scene *)scene
{
    [_parameters triggersChanged:scene];
    [_soundSystem triggersChanged:scene];
    [_midi triggersChanged:scene];
}

-(void)getParameters:(NSMutableDictionary *)putHere;
{
    // get parameters will configure the
    // defaults
    [_parameters getParameters:putHere];
    
    // so we have to do config work AFTER that
    NSString * eqName = _config.EQ;
    if( eqName )
        _parameters.selectedEQBandName = eqName;
    _config = nil; // ok, we're done now
}

- (void)getSettings:(NSMutableArray *)putHere
{
    
}

@end

@interface AutoPlayMidiFile : Audio
@end
@implementation AutoPlayMidiFile

-(void)start
{
    if( _midiFile )
    {
        if( _midi )
        {
            [_midi resume];
        }
        else
        {
            Instrument * instrument = [_instruments allValues][0];
            _midi = [[Midi alloc] init];
            [_midi playMidiFile:_midiFile withInstrument:instrument];
        }
    }
}


@end