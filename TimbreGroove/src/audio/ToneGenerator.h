//
//  ToneGenerator.h
//  TimbreGroove
//
//  Created by victor on 3/17/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "Midi.h"

@class Scene;
@class ToneGeneratorProxy;
@class ConfigToneGenerator;

@protocol ToneGeneratorProtocol <NSObject>

-(MIDISendBlock)renderProcForToneGenerator:(ToneGeneratorProxy *)generator;
-(void)getParameters:(NSMutableDictionary *)parameters;
-(void)triggersChanged:(Scene *)scene;

@end

@interface ToneGeneratorProxy : NSObject<MidiCapableProtocol>

+(id)toneGeneratorWithChannel:(int)channel andUI:(AudioUnit)au;

-(id<ToneGeneratorProtocol>)loadGenerator:(ConfigToneGenerator *)generatorConfig
                                                         midi:(Midi *)midi;
-(void)unloadGenerator;

@property (nonatomic,strong) id<ToneGeneratorProtocol> generator;
@property (nonatomic) AudioUnit au;
@property (nonatomic) int channel;
@property (nonatomic) MIDIPortRef     outPort;
@property (nonatomic) MIDIEndpointRef endPoint;

@end

