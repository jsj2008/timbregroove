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
#import "ToneGenerator.h"

@interface Audio () {
@protected
    SoundSystemParameters * _parameters;
    
    NSString * _eqName;
    NSArray *  _myTriggerMap;
    
    Midi *     _midi;
    MidiFile * _midiSequence;
    NSString * _midiFileName;
    bool       _started;
    
}

@end
@implementation Audio

+(id)audioFromConfig:(ConfigAudioProfile *)config withScene:(Scene *)scene
{
    Class klass = NSClassFromString(config.instanceClass);
    if( !klass )
        klass = [Audio class];
    Audio * audio = [klass new];
    NSDictionary * userData = config.customProperties;
    if( userData )
        [audio setValuesForKeysWithDictionary:userData];
    [audio loadAudioFromConfig:config];
    [audio->_soundSystem refreshGraph];
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

#if DEBUG
-(void)dealloc
{
    TGLog(LLObjLifetime, @"%@ released",self);
}
#endif

-(void)loadAudioFromConfig:(ConfigAudioProfile *)config
{
    NSMutableArray * soundSources = [NSMutableArray new];
#ifndef TG_DISABLE_AUIO
    for( ConfigInstrument * iconfig in config.instruments )
        [soundSources addObject:[_soundSystem loadInstrumentFromConfig:iconfig]];
    for( ConfigToneGenerator * tgconfig in config.generators )
        [soundSources addObject:[_soundSystem loadToneGeneratorFromConfig:tgconfig]];
    _myTriggerMap = config.connections;
    _midiFileName = config.midiFile;
#endif
    _soundSources = soundSources;
}

-(UInt32)channelFromName:(NSString *)name
{
    id<SoundSource> source = [self soundSourceFromName:name];
    if( source )
        return [source channel];
    return (UInt32)-1;
}

-(id<SoundSource>)soundSourceFromName:(NSString *)name
{
    for( id<SoundSource> source in _soundSources )
    {
        if( [[source name] isEqualToString:name] )
            return source;
    }
    return nil;
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
        [_soundSystem reattachInstruments:_soundSources];
        [_parameters restorePresets];
    }
    else
    {
        [self start];
    }

    if( _channelVolumes )
    {
        NSArray * arr = _soundSources;
        [_channelVolumes enumerateObjectsUsingBlock:^(NSNumber * value, NSUInteger idx, BOOL *stop) {
            _channelSelector( [ (id<ChannelProtocol>)arr[idx] channel] );
            _channelVolume( [value floatValue] );
        }];
    }
    
    TGLog( LLAudioResource, @"Audio graph waking up");
    CheckError(AUGraphStart(_soundSystem.processGraph),"Unable to start audio processing graph.");
    
}

-(void)pause
{
    if( _midiSequence )
        [_midiSequence pause];
    [_soundSystem dettachInstruments:_soundSources];
    TGLog( LLAudioResource, @"Audio graph going to sleep");
    CheckError(AUGraphStop(_soundSystem.processGraph),"Unable to stop audio processing graph.");
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
    
    if( scene )
    {
        TriggerMap * tm = scene.triggers;
        _channelSelector = [tm getIntTrigger:kParamChannel];
        _channelVolume   = [tm getFloatTrigger:kParamChannelVolume];
    }
    else
    {
        _channelSelector = nil;
        _channelVolume   = nil;
    }
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
        id<MidiCapableProtocol>  instrument = _soundSources[0];
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