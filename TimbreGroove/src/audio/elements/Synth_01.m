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
#import "SoundSystem.h"

@interface Synth_01 : Audio {
    PointerParamBlock _midiNote;
    PointerParamBlock _midiNoteON;
    PointerParamBlock _midiNoteOFF;
    IntParamBlock     _eqSwitch;
    FloatParamBlock   _eqCutOff;
    
    int _oscChannel;
    int _noiseChannel;
    MIDINoteMessage _mnm;
    MIDINoteMessage _noise;
    bool _notePlaying;
}

@end

@implementation Synth_01


-(void)loadAudioFromConfig:(ConfigAudioProfile *)config
{
    [super loadAudioFromConfig:config];
    self.channelVolumes = @[  @(0.01), @(0.6) ];
}
-(void)start
{
    [super start];
    _oscChannel = [self generatorChannelFromVirtual:0];
    _noiseChannel = [self generatorChannelFromVirtual:1];
    
    _noise.channel = _noiseChannel;
    _noise.note = 52;
    _noise.velocity = 127;
    
    _mnm.channel = _oscChannel;
    _mnm.velocity = 127;
    _mnm.note = 52;
}

-(void)getParameters:(NSMutableDictionary *)parameters
{
    [super getParameters:parameters];
    
    parameters[@"TapNote"] = [Parameter withBlock:^(CGPoint pt) {
        if( _notePlaying )
        {
            _midiNoteOFF(&_mnm);
            _midiNoteOFF(&_noise);
        }
        _mnm.duration = 0.4;
        _midiNote(&_mnm);
        _noise.duration = 0.4;
        _midiNote(&_noise);
    }];
    
    parameters[@"NoteSweep"] = [Parameter withBlock:^(float f) {
        if( !_notePlaying )
        {
            _notePlaying = true;
            _midiNoteON(&_mnm);
            _midiNoteON(&_noise);
        }
        _eqCutOff(-f);
    }];
    
    parameters[@"NoteDone"] = [Parameter withBlock:^(int type) {
        if( _notePlaying )
        {
            _midiNoteOFF(&_mnm);
            _midiNoteOFF(&_noise);
        }
        _notePlaying = false;
    }];
}


-(void)triggersChanged:(Scene *)scene
{
    [super triggersChanged:scene];
    
    if( scene )
    {
        TriggerMap * tm = scene.triggers;
        
        _midiNote    = [tm getPointerTrigger:kParamMIDINote];
        _midiNoteON  = [tm getPointerTrigger:kParamMIDINoteON];
        _midiNoteOFF = [tm getPointerTrigger:kParamMIDINoteOFF];
        _eqCutOff = [tm getFloatTrigger:kParamEQLowCutoff];
        _eqSwitch    = [tm getIntTrigger:kParamEQLowPassEnable];
        _eqSwitch(1);
        
    }
    else
    {
        _eqSwitch(0);
        _eqSwitch = nil;
        _eqCutOff = nil;
        
        _midiNote    = nil;
        _midiNoteON  = nil;
        _midiNoteOFF = nil;
    }
}


@end
