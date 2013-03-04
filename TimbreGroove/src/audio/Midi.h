//
//  Midi.h
//  TimbreGroove
//
//  Created by victor on 2/10/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "SoundSystem.h"

@interface Midi : NSObject

-(void)playMidiFile:(NSString *)filename withInstrument:(Instrument *)instrument;
-(BOOL)isPlayerDone;
-(void)pause;
-(void)resume;

-(void)getParameters:(NSMutableDictionary *)putHere;
-(void)update:(NSTimeInterval)dt;

@end
