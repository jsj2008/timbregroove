//
//  ToneGenerator.m
//  TimbreGroove
//
//  Created by victor on 3/17/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "ToneGenerator.h"
#import "Config.h"

@implementation ToneGenerator {
    // the callback block is passed to iOS
    // midi engine as (bridge void *) so
    // we need to hold onto the callback
    // block to maintain a ref count of 1
    id _callback;
}

+(id)toneGeneratorWithMixerAU:(AudioUnit)au
                       config:(ConfigToneGenerator *)config
                         midi:(Midi *)midi
{
    Class klass = NSClassFromString(config.instanceClass);
    ToneGenerator * generator = [[klass alloc] init];
    generator.midi = midi;
    generator.mixerAU = au;
    NSDictionary * userData = config.customProperties;
    if( userData )
        [generator setValuesForKeysWithDictionary:userData];
    
    return generator;
}


#if DEBUG
-(void)dealloc
{
    TGLog(LLAudioResource, @"%@ released",self);
}
#endif

-(void)didAttachToGraph:(SoundSystem *)ss
{
    [_midi makeDestination:self];
}

-(void)didDetachFromGraph:(SoundSystem *)ss
{
    [self detach];
    [_midi releaseDestination:self];
}

-(MIDISendBlock)callback
{
    if( !_callback )
        _callback = [self midiRenderProc];
    return _callback;
}

-(MIDISendBlock)midiRenderProc
{
    return nil;
}

-(void)detach
{
    
}

-(void)getParameters:(NSMutableDictionary *)parameters
{
    
}
-(void)triggersChanged:(Scene *)scene
{
    
}

@end
