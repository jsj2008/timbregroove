//
//  ToneGenerator.h
//  TimbreGroove
//
//  Created by victor on 3/17/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "SoundSource.h"

@class Scene;
@class ConfigToneGenerator;
@class Midi;

@interface ToneGenerator : NSObject<SoundSource>

+(id)toneGeneratorWithMixerAU:(AudioUnit)au
                       config:(ConfigToneGenerator *)generatorConfig
                         midi:(Midi *)midi;


@property (nonatomic,strong) Midi *   midi;
@property (nonatomic) AudioUnit       mixerAU;
@property (nonatomic) int             channel;
@property (nonatomic) MIDIPortRef     outPort;
@property (nonatomic) MIDIEndpointRef endPoint;

@property (nonatomic,strong) NSString * name;

// derived classes
-(MIDISendBlock)midiRenderProc;
-(void)getParameters:(NSMutableDictionary *)parameters;
-(void)triggersChanged:(Scene *)scene;

@end

