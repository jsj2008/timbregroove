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
#endif

#define  kFramesForDisplay 512

#define CheckError(error,str) { if (error != noErr) { _CheckError(error,str); } }

void _CheckError( OSStatus error, const char *operation);

@class ConfigInstrument;

@interface Instrument : NSObject
-(OSStatus)playNote:(int)note forDuration:(NSTimeInterval)duration;

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
    AudioUnit *      _samplerUnits;
    AudioUnit        _ioUnit;
    AudioUnit        _mixerUnit;
    AudioUnit        _masterEQUnit;
    AUNode           _mixerNode;
    Float64          _graphSampleRate;

    int              _selectedEQBand; // actually eqBands
    int              _selectedChannel; // aka bus, aka element
    
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
