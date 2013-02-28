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
#import "Mixer+Parameters.h"
#import "Config.h"
#import "Scene.h"
#import "NSValue+Parameter.h"
#import "Names.h"

@interface Audio () {
@protected
    Mixer * _mixer;
    NSString * _midiFile;
    ConfigAudioProfile * _config;
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

-(void)dealloc
{
    NSLog(@"Audio object gone");
}

-(void)loadAudioFromConfig:(ConfigAudioProfile *)config
{
    NSDictionary * instrumentConfigs = config.instruments;
    _instruments = [NSMutableDictionary new];
    for( NSString * name in instrumentConfigs )
        _instruments[name] = [_mixer loadInstrumentFromConfig:instrumentConfigs[name]];
    _midiFile = config.midiFile;
    _config = config;
}

-(void)start
{
}

-(void)play
{
    [_mixer resumeMidi];
}

-(void)pause
{
    [_mixer pauseMidiFile];
}

-(void)update:(NSTimeInterval)dt scene:(Scene *)scene
{
    MixerUpdate mu = {0};
    [_mixer update:&mu];
    if( mu.audioBufferList )
    {
        ParamPayload pv;
        pv.v.mu = mu;
        pv.type = TG_MIXERUPDATE;
        pv.additive = false;
        pv.duration = 0;
        [scene setTrigger:kTriggerAudioFrame withValue:[NSValue valueWithPayload:pv]];
    }
}

-(NSDictionary *)getParameters
{
    // get parameters will configure the
    // defaults
    NSDictionary * dict = [_mixer getParameters];
    
    // so we have to do config work AFTER that
    NSString * eqName = _config.EQ;
    if( eqName )
        _mixer.selectedEQBandName = eqName;
    _config = nil; // ok, we're done now

    return dict;
    
}
@end

@interface AutoPlayMidiFile : Audio
@end
@implementation AutoPlayMidiFile

-(void)start
{
    if( _midiFile )
    {
        Instrument * instrument = nil;
        for( NSString * name in _instruments )
        {
            instrument = _instruments[name];
            break;
        }
        [_mixer playMidiFile:_midiFile withInstrument:instrument];
    }
}


@end