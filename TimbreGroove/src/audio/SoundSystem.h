//
//  Mixer.h
//  TimbreGroove
//
//  Created by victor on 1/27/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMIDI/CoreMIDI.h>
#import "TGTypes.h"

@class Scene;

#define  kFramesForDisplay 512

#define CheckError(error,str) { if (error != noErr) { _CheckError(error,str); } }

void _CheckError( OSStatus error, const char *operation);

@class ConfigInstrument;
@class Sampler;
@class ConfigToneGenerator;
@class ToneGenerator;
@class SoundSystemParameters;
@class Midi;

// AU Lab reports one octive below
// these. So:
// AULab C4 == kC5
//
enum MidiNotes {
    kC0 = 0,
    kC1 = 12,
    kC2 = 24,
    kC3 = 36,
    kC4 = 48,
    kC5 = 60,
    kMiddleC = kC5,
    kA440 = 69,
    kC6 = 72,
    kC7 = 84,
};

@interface SoundSystem : NSObject 
+(SoundSystem *)sharedInstance;

-(Sampler *)loadInstrumentFromConfig:(ConfigInstrument *)config;
-(ToneGenerator *)loadToneGeneratorFromConfig:(ConfigToneGenerator *)config;

-(void)dettachInstruments:(NSArray *)soundSources;
-(void)reattachInstruments:(NSArray *)soundSources;
-(void)plugInstrumentIntoBus:(Sampler *)instrument;
-(void)unplugInstrumentFromBus:(Sampler *)instrument;
-(OSStatus)configUnit:(AudioUnit)unit;
-(OSStatus)refreshGraph;

@property (nonatomic,readonly) AudioUnit mixerUnit;
@property (nonatomic,readonly) AudioUnit masterEQUnit;
@property (nonatomic,readonly) AUGraph processGraph;
@property (nonatomic) Float64 graphSampleRate;
@property (nonatomic,strong) Midi * midi;
-(void)update:(NSTimeInterval)dt;
-(void)getParameters:(NSMutableDictionary *)putHere;
-(void)triggersChanged:(Scene *)scene;
@end
