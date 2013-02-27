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

#ifndef SKIP_MIXER_DECLS
extern const AudioUnitParameterValue kEQBypassON;
extern const AudioUnitParameterValue kEQBypassOFF;
extern const int kMaxChannels;
#endif

#define  kFramesForDisplay 512

#define CheckError(error,str) { if (error != noErr) { _CheckError(error,str); } }

void _CheckError( OSStatus error, const char *operation);

@class ConfigInstrument;

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


@interface Instrument : NSObject
-(OSStatus)playNote:(int)note forDuration:(NSTimeInterval)duration;

@property (nonatomic,readonly) int channel;
@property (nonatomic,readonly) int lowestPlayable;
@property (nonatomic,readonly) int highestPlayable;
@property (nonatomic,readonly) AudioUnit sampler;
@end

typedef enum ExpectedTriggerFlags {
    kNoOneExpectsNothin = 0,
    kExpectsPeak = 1,
    kExpectsPeakHold = 1 << 1
} ExpectedTriggerFlags;

@interface Mixer : NSObject {
@private
    // here for categories
    AUGraph          _processingGraph;

    AudioUnit        _ioUnit;
    AudioUnit        _mixerUnit;
    AudioUnit        _masterEQUnit;
    AUNode           _mixerNode;
    Float64          _graphSampleRate;

    NSString *       _selectedEQBandName;
    int              _selectedEQBand; // actually eqBands
    int              _selectedChannel; // aka bus, aka element
    int              _numChannels;
    
    NSArray *        _auParameters;
    
    ExpectedTriggerFlags _expectedTriggerFlags;
    
    MIDIClientRef  _midiClient;
    MusicTimeStamp _playerTrackLength;
    MusicSequence  _currentSequence;
    MusicPlayer    _musicPlayer;
    bool           _midiFilePlaying;
}

+(Mixer *)sharedInstance;

-(Instrument *)loadInstrumentFromConfig:(ConfigInstrument *)config;

-(NSDictionary *)getParameters;

-(void)update:(MixerUpdate *)mixerUpdate;

@end
