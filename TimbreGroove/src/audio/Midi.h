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

enum {
    kMIDIMessage_NoteOn    = 0x9,
    kMIDIMessage_NoteOff   = 0x8,
};

/*
(OSStatus)SendEvent:
 (UInt32)inStatus
inData1:(UInt32)inData1
inData2:(UInt32)inData2
inOffsetSampleFrame:(UInt32)inOffsetSampleFrame;
*/

typedef OSStatus (^MIDISendBlock)(UInt32,UInt32,UInt32,UInt32);

// Wrap AU devices and implement Tone generators with this
@protocol MidiCapableProtocol <NSObject>
-(MIDISendBlock)callback;
-(void)setEndPoint:(MIDIEndpointRef)endPoint;
-(MIDIEndpointRef)endPoint;
-(void)setOutPort:(MIDIPortRef)outPort;
-(MIDIPortRef)outPort;
@end

@interface MidiFile : NSObject
-(void)start;
-(void)pause;
-(void)resume;
@end

@interface Midi : NSObject

-(MidiFile *)setupMidiFile:(NSString *)filename
            withInstrument:(id<MidiCapableProtocol>)instrument
                        ss:(SoundSystem *)ss;
-(void)makeDestination:(id<MidiCapableProtocol>)instrument;
-(void)releaseDestination:(id<MidiCapableProtocol>)instrument;
-(void)sendNote:(MIDINoteMessage *)noteMsg
    destination:(id<MidiCapableProtocol>)instrument;
-(void)setNoteOnOff:(MIDINoteMessage *)noteMsg
        destination:(id<MidiCapableProtocol>)instrument
                 on:(bool)on;

-(void)update:(NSTimeInterval)dt;

@end
