//
//  Synth.m
//  TimbreGroove
//
//  Created by victor on 3/18/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Audio.h"
#import "TriggerMap.h"
#import "Scene.h"
#import "Names.h"
#import "NoteGenerator.h"

@interface Synth : Audio {
    PointerParamBlock _midiNote;
    int _oscChannel;
    int _currentChannel;

    NoteGenerator * _notes;
}

@end

@implementation Synth


-(void)loadAudioFromConfig:(ConfigAudioProfile *)config
{
    [super loadAudioFromConfig:config];
    self.channelVolumes = @[ @(0.25), @(0.1), @(0.1) ];
}
-(void)start
{
    [super start];
    _oscChannel = [self generatorChannelFromVirtual:0];
    _notes = [[NoteGenerator alloc] initWithScale:kScalePentatonic isRandom:true andRange:(NoteRange){55,81}];
}

-(void)getParameters:(NSMutableDictionary *)parameters
{
    [super getParameters:parameters];
    
    parameters[@"TapNote"] = [Parameter withBlock:^(CGPoint pt) {
        MIDINoteMessage mnm;
        mnm.note = [_notes next];
        mnm.duration = 0.4;
        mnm.velocity = 127;
        mnm.channel = _oscChannel + _currentChannel;
        _midiNote(&mnm);
        mnm.note = [_notes next];
        _currentChannel = (_currentChannel + mnm.note) % 3;
        mnm.channel = _oscChannel + _currentChannel;
        _midiNote(&mnm);
        _currentChannel = ++_currentChannel % 3;
    }];
}


-(void)triggersChanged:(Scene *)scene
{
    [super triggersChanged:scene];
    
    if( scene )
    {
        TriggerMap * tm = scene.triggers;
        
        _midiNote = [tm getPointerTrigger:kParamMIDINote];
    }
    else
    {
        _midiNote = nil;
    }
}


@end
