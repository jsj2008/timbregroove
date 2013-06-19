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
    Midi * _midi;
}

@end
@implementation ToneGeneratorProxy

+(id)toneGeneratorWithMixerAU:(AudioUnit)au
{
    return [[ToneGeneratorProxy alloc] initWithMixerAU:au];
}

-(id)initWithMixerAU:(AudioUnit)au
{
    self = [super init];
    if( self )
    {
        _au = au;
    }
    return self;
}

#if DEBUG
-(void)dealloc
{
    TGLog(LLAudioResource, @"%@ released",self);
}
#endif

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
    return _generator;
}

-(void)didAttachToGraph:(int)atChannel
{
    _channel = atChannel;
    _tgCallback = [_generator renderProcForToneGenerator:self];
    [_midi makeDestination:self];
}

-(void)didDetachFromGraph
{
    if( _generator )
        [_generator detach];
    _tgCallback = nil;
    [_midi releaseDestination:self];
}

@end
