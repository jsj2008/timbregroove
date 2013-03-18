//
//  Instrument.h
//  TimbreGroove
//
//  Created by victor on 2/28/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class ConfigInstrument;
@class Midi;

enum {
    kMIDIMessage_NoteOn    = 0x9,
    kMIDIMessage_NoteOff   = 0x8,
};


@interface Sampler : NSObject

+(id)instrumentWithConfig:(ConfigInstrument *)config
                 andGraph:(AUGraph)graph;

-(void)loadSound:(ConfigInstrument *)config;
-(void)releaseSound;

-(id)initWithGraph:(AUGraph)graph;
-(void)setNodeIntoGraph;
-(void)setupMidi:(Midi *)midi;

-(void)sendNote:(MIDINoteMessage *)noteMsg;

@property (nonatomic,readonly) int lowestPlayable;
@property (nonatomic,readonly) int highestPlayable;
@property (nonatomic,readonly) AudioUnit sampler;
@property (nonatomic,readonly) AUNode    graphNode;
@property (nonatomic) bool configured;
@property (nonatomic) MIDIPortRef     outPort;
@property (nonatomic) MIDIEndpointRef midiEndPoint;
@property (nonatomic) int channel;
@property (nonatomic,readonly) bool available;
@end

