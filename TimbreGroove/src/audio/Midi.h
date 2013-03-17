//
//  Midi.h
//  TimbreGroove
//
//  Created by victor on 2/10/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "SoundSystem.h"

@class Scene;
@class Midi;

@interface MidiFile : NSObject
-(void)start;
-(void)pause;
-(void)resume;
@end

@interface MidiFreeRange : NSObject

@end

@interface Midi : NSObject

-(MidiFile *)setupMidiFile:(NSString *)filename withInstrument:(Instrument *)instrument ss:(SoundSystem *)ss;
-(MidiFreeRange *)setupMidiFreeRange:(NSArray *)instruments;
-(void)getParameters:(NSMutableDictionary *)putHere;
-(void)update:(NSTimeInterval)dt;
-(void)triggersChanged:(Scene *)scene;


@property (nonatomic) MIDIClientRef midiClient;
@end
