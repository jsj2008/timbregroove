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
#import "MixerParamConsts.h"

#define CheckError(error,str) { if (error != noErr) { _CheckError(error,str); } }

void _CheckError( OSStatus error, const char *operation);

@interface Sound : NSObject
-(OSStatus)playNote:(int)note forDuration:(NSTimeInterval)duration;
-(void)playMidiFile:(NSString *)filename;
-(void)addNoteCache:(int)note ts:(MIDITimeStamp)ts;
@property (nonatomic,readonly) int lowestPlayable;
@property (nonatomic,readonly) int highestPlayable;
@property (nonatomic,readonly) AudioUnit sampler;
@end

static const UInt32 kFramesForDisplay = 512;

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

    NSDictionary *          _globalsParamMap;
    AudioUnitParameterValue _mixerOutputGain;
    int                     _selectedEQBand; // actually eqBands
    
    MIDIClientRef  _midiClient;
    MusicTimeStamp _playerTrackLength;
    MusicSequence  _currentSequence;
    MusicPlayer    _musicPlayer;
    bool           _midiFilePlaying;
}

+(Mixer *)sharedInstance;

-(Sound *)getSound:(NSString *)name;
-(NSArray *)getAllSoundNames;

-(void)update:(MixerUpdate *)mixerUpdate;


@end
