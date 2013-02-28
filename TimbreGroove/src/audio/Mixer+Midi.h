//
//  Mixer+Midi.h
//  TimbreGroove
//
//  Created by victor on 2/10/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Mixer.h"

@interface Mixer (Midi)
-(void)setupMidi;

-(void)playMidiFile:(NSString *)filename withInstrument:(Instrument *)instrument;
-(BOOL)isPlayerDone;
-(void)pauseMidiFile;
-(void)resumeMidi;

-(void)midiDealloc;
@end
