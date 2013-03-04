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
}

@end
@implementation Serenity

-(void)start
{
    _scale = [Pentatonic new];
    Scene * scene = [Global sharedInstance].scene;
    [scene setParameter:kParamChannelVolume value:0 func:kTweenLinear duration:0];
    [super start];
}

-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];
    
    Instrument * synth = _instruments[@"vibes"];

    putHere[@"SwellSound"] = ^(NSValue *nsv){
        //CGPoint pt = [nsv CGPointValue];
        Scene * scene = [Global sharedInstance].scene;
        [synth playNote:[_scale up] forDuration:3.0]; [_scale up]; [_scale up];
        [synth playNote:[_scale up] forDuration:3.0]; [_scale up];
        [scene setParameter:kParamChannel value:synth.channel func:kTweenLinear duration:0];
        [scene setParameter:kParamChannelVolume value:1.0 func:kTweenSwellInOut duration:1.5];
    };
}
@end
