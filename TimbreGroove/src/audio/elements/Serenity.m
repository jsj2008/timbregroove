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

@interface Pentatonic : NSObject {
    int * _notes;
    int _count;
}
@end

@implementation Pentatonic

- (id)init
{
    self = [super init];
    if (self) {
        static int notes[8] = {
            kMiddleC,
            kMiddleC + 3,
            kMiddleC + 5,
            kMiddleC + 7,
            kMiddleC + 9,
            kMiddleC + 11,
            kMiddleC + 14,
            kMiddleC + 16
        };
        _notes = notes;
    }
    return self;
}

-(int)up
{
    return _notes[ _count++ % 8 ] - 5;
}

-(int)note:(int)num
{
    int note = _notes[ abs(num % 6) ] - 11;
    NSLog(@"i:%d  note:%d",num,note);
    return note;
}
@end


@interface Serenity : Audio

@end

@interface Serenity() {
    Pentatonic * _scale;
    FloatParamBlock _channelVolume;
    FloatParamBlock _channelVolumeDecay;
    IntParamBlock   _selectChannel;
    PointerParamBlock _midiNote;
}

@end
@implementation Serenity

-(void)start
{
    _scale = [Pentatonic new];
    [super start];
}

-(void)triggersChanged:(Scene *)scene
{
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
                                  _selectChannel(0); //_selectChannel(synth.channel);
                                  _channelVolume(0);
                                  mnm.note = [_scale up];
                                  mnm.duration = 1.1;
                                  mnm.velocity = 127;
                                  _midiNote(&mnm);
                                  mnm.note = [_scale up];
                                  _midiNote(&mnm);
                                  _channelVolumeDecay(1.0);
                              //    [NSObject performBlock:^{_channelVolumeDecay(0);} afterDelay:0.5];
                              }];
}
@end
