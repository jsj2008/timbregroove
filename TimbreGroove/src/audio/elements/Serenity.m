//
//  Senerity.m
//  TimbreGroove
//
//  Created by victor on 2/25/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Serenity.h"
#import "Global.h"
#import "Scene.h"
#import "Names.h"
#import "Mixer.h"

@implementation Serenity

-(void)start
{
    Scene * scene = [Global sharedInstance].scene;
    [scene setParameter:kParamChannelVolume value:0 func:kTweenLinear duration:0];
    [super start];
}

-(NSDictionary *)getParameters
{
    NSDictionary * dict = [super getParameters];
    
    NSMutableDictionary * mine = [NSMutableDictionary dictionaryWithDictionary:dict];
    dict = nil;
    Instrument * synth = _instruments[@"ambience"];
    mine[@"SwellSound"] = ^(NSValue *nsv) {
        Scene * scene = [Global sharedInstance].scene;
        [synth playNote:kMiddleC forDuration:3.0];
        [scene setParameter:kParamChannel value:synth.channel func:kTweenLinear duration:0];
        [scene setParameter:kParamChannelVolume value:1.0 func:kTweenSwellInOut duration:1.5];
    };
    
    return mine;
}
@end
