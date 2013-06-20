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
    FloatParamBlock   _noiseParam;
    
    MIDINoteMessage _sawMsg;
    MIDINoteMessage _kelvinMsg;
    bool _notePlaying;
}

@property (nonatomic) float noiseFactor;
@end

@implementation Synth_01


-(void)loadAudioFromConfig:(ConfigAudioProfile *)config
{
    [super loadAudioFromConfig:config];
    self.channelVolumes = @[  @(0.9), @(0.9) ];
}

-(void)start
{
    [super start];
    _sawMsg.channel = [self channelFromName:@"saw"];
    _sawMsg.velocity = 127;
    _sawMsg.note = 52;

    _kelvinMsg.channel = [self channelFromName:@"kelvin"];
    _kelvinMsg.velocity = 127;
    _kelvinMsg.note = kC5;
    
    if( _noiseFactor )
        _noiseParam(_noiseFactor);
    _noiseParam = nil;
}

-(void)activate
{
    [super activate];
    [NSObject performBlock:^{
        _midiNoteON(&_kelvinMsg);
    } afterDelay:0.9];
}

-(void)pause
{
    _midiNoteOFF(&_kelvinMsg);
    [super pause];
}

-(void)getParameters:(NSMutableDictionary *)parameters
{
    [super getParameters:parameters];
    
    parameters[@"TapNote"] = [Parameter withBlock:^(CGPoint pt) {
        if( _notePlaying )
        {
            _midiNoteOFF(&_sawMsg);
        }
        _sawMsg.duration = 0.4;
        _midiNote(&_sawMsg);        
    }];
    
    parameters[@"NoteSweep"] = [Parameter withBlock:^(float f) {
        if( !_notePlaying )
        {
            _notePlaying = true;
            _midiNoteON(&_sawMsg);
        }
        _eqCutOff(-f);
    }];
    
    parameters[@"NoteDone"] = [Parameter withBlock:^(int type) {
        if( _notePlaying )
        {
            _midiNoteOFF(&_sawMsg);
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
        _eqCutOff    = [tm getFloatTrigger:kParamEQLowCutoff];
        _eqSwitch    = [tm getIntTrigger:kParamEQLowPassEnable];
        _eqSwitch(1);
        _noiseParam  = [tm getFloatTrigger:@"OscNoiseFactor"];

    }
    else
    {
        _eqSwitch(0);
        _eqSwitch = nil;
        _eqCutOff = nil;
        
        _midiNote    = nil;
        _midiNoteON  = nil;
        _midiNoteOFF = nil;
        
        _noiseParam  = nil;
    }
}


@end
