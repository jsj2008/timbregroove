//
//  ToneGenerator.m
//  TimbreGroove
//
//  Created by victor on 3/17/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "ToneGenerator.h"
#import "Config.h"

@interface ToneGeneratorProxy () {
    id _tgCallback;
    __weak Midi * _midi;
}

@end
@implementation ToneGeneratorProxy

+(id)toneGeneratorWithChannel:(int)channel andMixerAU:(AudioUnit)au
{
    return [[ToneGeneratorProxy alloc] initWithChannel:channel andAU:au];
}

-(id)initWithChannel:(int)channel andAU:(AudioUnit)au
{
    self = [super init];
    if( self )
    {
        _au = au;
        _channel = channel;
    }
    return self;
}

-(void)dealloc
{
    [self detach];
    TGLog(LLAudioResource, @"%@ released",self);
}


-(MIDISendBlock)callback
{
    return _tgCallback;
}

-(id<ToneGeneratorProtocol>)loadGenerator:(ConfigToneGenerator *)config
                                     midi:(Midi *)midi;
{
    _midi = midi;
    Class klass = NSClassFromString(config.instanceClass);
    _generator = [[klass alloc] init];
    NSDictionary * userData = config.customProperties;
    if( userData )
        [(NSObject *)_generator setValuesForKeysWithDictionary:userData];
    [self attach:_channel];
    return _generator;
}

-(void)attach:(int)atChannel
{
    _channel = atChannel;
    _tgCallback = [_generator renderProcForToneGenerator:self];
    [_midi makeDestination:self];
}

-(void)detach
{
    if( _generator )
        [_generator detach];
    _tgCallback = nil;
    [_midi releaseDestination:self];
}

-(void)unloadGenerator
{
    [self detach];
    _tgCallback = nil;
}
@end
