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
#import "SoundSystem+Parameters.h"
#import "Config.h"
#import "Scene.h"
#import "NSValue+Parameter.h"
#import "Names.h"
#import "Instrument.h"

@interface Audio () {
@protected
    SoundSystem *        _soundSystem;
    NSString *           _midiFile;
    ConfigAudioProfile * _config;
    Midi *               _midi;
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
        _soundSystem = [SoundSystem sharedInstance];
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
    NSDictionary * instrumentConfigs = config.instruments;
    _instruments = [NSMutableDictionary new];
    for( NSString * name in instrumentConfigs )
        _instruments[name] = [_soundSystem loadInstrumentFromConfig:instrumentConfigs[name]];
    _midiFile = config.midiFile;
    _config = config;
}

-(void)start
{
}

-(void)play
{
    for( Instrument * instrument in [_instruments allValues] )
    {
        [_soundSystem plugInstrumentIntoBus:instrument];
    }
    if( _midi )
        [_midi resume];
}

-(void)pause
{
    if( _midi )
        [_midi pause];
    
    for( Instrument * instrument in [_instruments allValues] )
    {
        [_soundSystem unplugInstrumentFromBus:instrument];
    }
}

-(void)update:(NSTimeInterval)dt scene:(Scene *)scene
{
    AudioFrameCapture mu = {0};
    [_soundSystem update:&mu];
    if( mu.audioBufferList )
    {
        ParamPayload pv;
        pv.v.mu = mu;
        pv.type = TG_MIXERUPDATE;
        pv.additive = false;
        pv.duration = 0;
        NSValue * nsv = [NSValue valueWithPayload:pv];
        [scene setTrigger:kTriggerAudioFrame withValue:nsv];
    }
}

-(void)getParameters:(NSMutableDictionary *)putHere;
{
    // get parameters will configure the
    // defaults
    [_soundSystem getParameters:putHere];
    
    // so we have to do config work AFTER that
    NSString * eqName = _config.EQ;
    if( eqName )
        _soundSystem.selectedEQBandName = eqName;
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