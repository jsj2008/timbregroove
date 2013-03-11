//
//  Senerity.m
//  TimbreGroove
//
//  Created by victor on 2/25/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Global.h"
#import "Scene.h"
#import "Names.h"
#import "SoundSystem.h"
#import "Audio.h"
#import "Instrument.h"
#import "TriggerMap.h"
#import "NSString+Tweening.h"
#import "NoteGenerator.h"

#define AMBIENCE_CHANNEL 1
#define CONGAS_CHANNEL   0

@interface Serenity : Audio

@end

@interface Serenity() {
    NoteGenerator * _congasScale;
    NoteGenerator * _ambientScale;
    FloatParamBlock _channelVolume;
    FloatParamBlock _channelVolumeDecay;
    IntParamBlock   _selectChannel;
    PointerParamBlock _midiNote;
}

@end
@implementation Serenity

-(void)start
{
    Instrument * congas = _instruments[CONGAS_CHANNEL];
    NoteRange congasRange = (NoteRange){ congas.lowestPlayable, congas.highestPlayable };
    _congasScale = [[NoteGenerator alloc] initWithScale:kScaleSemitones isRandom:false andRange:congasRange];
    
    _ambientScale = [[NoteGenerator alloc] initWithScale:kScaleMinor isRandom:true];
    _ambientScale.range = (NoteRange){ 45, 80 };
    [super start];
}

-(void)triggersChanged:(Scene *)scene
{
    [super triggersChanged:scene];
    
    static NSString const * kChannelVolumeDecay = nil;
    
    if( !kChannelVolumeDecay )
        kChannelVolumeDecay = [kParamChannelVolume stringByAppendingTween:kTweenEaseInSine len:0.5];

    TriggerMap * tm = scene.triggers;
    _channelVolume      = [tm getFloatTrigger: kParamChannelVolume];
    _channelVolumeDecay = [tm getFloatTrigger  :kChannelVolumeDecay];
    _selectChannel      = [tm getIntTrigger    :kParamChannel];
    _midiNote           = [tm getPointerTrigger:kParamMIDINote];
    
    _channelVolume(0.0);
}

-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];
    
    putHere[@"SwellSound"] = [Parameter withBlock:
                              ^(CGPoint pt)
                              {
                                  MIDINoteMessage mnm;
                                  _selectChannel(AMBIENCE_CHANNEL);
                                  _channelVolume(0);
                                  mnm.note = [_ambientScale next];
                                  mnm.duration = 1.1;
                                  mnm.velocity = 127;
                                  mnm.channel = AMBIENCE_CHANNEL;
                                  _midiNote(&mnm);
                                  mnm.note = [_ambientScale next];
                                  _midiNote(&mnm);
                                  _channelVolumeDecay(1.0);
                              }];
}
@end
