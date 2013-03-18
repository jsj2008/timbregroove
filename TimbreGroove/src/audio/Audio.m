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
#import "Sampler.h"

@interface Audio () {
@protected
    SoundSystemParameters * _parameters;
    
    NSString * _eqName;
    NSArray * _myTriggerMap;
    
    Midi *     _midi;
    MidiFile * _midiSequence;
    NSString * _midiFileName;
    bool _started;
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
        _ssp = _parameters;
        _midi = _soundSystem.midi;
    }
    return self;
}

-(void)dealloc
{
    [_instruments each:^(Sampler * sampler) {
        [sampler releaseSound];
    }];
}
-(void)loadAudioFromConfig:(ConfigAudioProfile *)config
{
    _instruments = [config.instruments map:^id(id instrumentConfig) {
        return [_soundSystem loadInstrumentFromConfig:instrumentConfig];
    }];
    _myTriggerMap = config.connections;
    _midiFileName = config.midiFile;
}

-(UInt32)realChannelFromVirtual:(UInt32)virtualChannel
{
    return ((Sampler *)_instruments[virtualChannel]).channel;
}

-(void)start
{
    _started = true;
    
    if( _midiSequence )
        [_midiSequence start];
}

-(void)activate
{
    if( _started )
    {
        if( _midiSequence )
            [_midiSequence resume];
    }
    else
    {
        [self start];
    }
}

-(void)pause
{
    if( _midiSequence )
        [_midiSequence pause];
    
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
}

-(void)getParameters:(NSMutableDictionary *)putHere;
{
    // get parameters will configure the
    // defaults
    [_parameters getParameters:putHere];
    [_soundSystem getParameters:putHere];
}

-(void)getTriggerMap:(NSMutableArray *)putHere
{
    if( _myTriggerMap )
       [putHere addObjectsFromArray:_myTriggerMap];
}

- (void)getSettings:(NSMutableArray *)putHere
{
    
}

-(void)startMidiFile
{
    if( _midiFileName && !_midiSequence )
    {
        Sampler * instrument = _instruments[0];
        _midiSequence = [_midi setupMidiFile:_midiFileName withInstrument:instrument ss:_soundSystem];
    }
}

@end

@interface AutoPlayMidiFile : Audio
@end
@implementation AutoPlayMidiFile

-(void)start
{
    [super startMidiFile];
    [super start];
}


@end