//
//  Names.h
//  TimbreGroove
//
//  Created by victor on 2/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 objects export Parameters - tweekable properties
 Audio
 - master volume
 - eq freq
 - eq peak
 - eq bandwidth
 - tempo
 - instrumentation?
 - (MIDI stuff)
 - pitch
 - AUPreset Perf. Params 1-8
 
 Visual
 - color
 - placement
 - scale
 - distortion(s)
 - rotation
 - lighting
 
 objects export Triggers - tweeking events
 User
 - gestures
 - button pushes
 - shake
 - tilt
 - location(?)
 Audio
 - peak (dynamics)
 - fft/freq
 - tempo (pulse)
 - MIDI note
 - Chords (?)

 kMood_Peace,
 kMood_Happy,
 kMood_Dark,
 kMood_Troubling,
 kMood_Loony,
 
 */


extern NSString const * kMoodPeace;
extern NSString const * kMoodHappy;
extern NSString const * kMoodTroubling;
extern NSString const * kMoodLoony;
extern NSString const * kMoodDark;
extern NSString const * kMoodSexy;

extern NSString const * kParamMasterVolume;
extern NSString const * kParamTempo;
extern NSString const * kParamMIDINote;
extern NSString const * kParamRandomNote;
extern NSString const * kParamPitch;

extern NSString const * kParamChannel;
extern NSString const * kParamChannelVolume;

extern NSString const * kParamEQLowPassEnable;
extern NSString const * kParamEQParametricEnable;
extern NSString const * kParamEQHiPassEnable;

extern NSString const * kParamEQLowCutoff;
extern NSString const * kParamEQLowResonance;
extern NSString const * kParamEQMidCenterFrequency;
extern NSString const * kParamEQMidBandwidth;
extern NSString const * kParamEQMidGain;
extern NSString const * kParamEQHighCutoff;
extern NSString const * kParamEQHighResonance;

extern NSString const * kParamAudioFrameCapture;

extern NSString const * kParamInstrumentP1;
extern NSString const * kParamInstrumentP2;
extern NSString const * kParamInstrumentP3;
extern NSString const * kParamInstrumentP4;
extern NSString const * kParamInstrumentP5;
extern NSString const * kParamInstrumentP6;
extern NSString const * kParamInstrumentP7;
extern NSString const * kParamInstrumentP8;

extern NSString const * kParamColor;
extern NSString const * kParamPlacement;
extern NSString const * kParamScale;
extern NSString const * kParamShape;
extern NSString const * kParamRotation;
extern NSString const * kParamRotationX;
extern NSString const * kParamRotationY;
extern NSString const * kParamRotationZ;
extern NSString const * kParamLightDirection;
extern NSString const * kParamLightColor;
extern NSString const * kParamNewElement;

extern NSString const * kTriggerVPad1;
extern NSString const * kTriggerVPad2;
extern NSString const * kTriggerVPad3;
extern NSString const * kTriggerVPad4;
extern NSString const * kTriggerVPad5;

extern NSString const * kTriggerTimer;
extern NSString const * kTriggerUpdate;
extern NSString const * kTriggerTick;


extern NSString const * kTriggerTapPos;
extern NSString const * kTriggerTap1;
extern NSString const * kTriggerTap2;
extern NSString const * kTriggerTap3;
extern NSString const * kTriggerDblTap;
extern NSString const * kTriggerPanX;
extern NSString const * kTriggerPanY;
extern NSString const * kTriggerDragPos;
extern NSString const * kTriggerDrag1;
extern NSString const * kTriggerDrag2;
extern NSString const * kTriggerDrag3;
extern NSString const * kTriggerDirection;
extern NSString const * kTriggerRotate;
extern NSString const * kTriggerPinch;
extern NSString const * kTriggerHold1;
extern NSString const * kTriggerHold2;
extern NSString const * kTriggerHoldAndDrag;
extern NSString const * kTriggerHoldAndTap;
extern NSString const * kTriggerMainSlider;

extern NSString const * kTriggerDynamicPeak;
extern NSString const * kTriggerDynamicHold;
extern NSString const * kTriggerFrequencyPeak;
extern NSString const * kTriggerBeat;
extern NSString const * kTriggerNote;
extern NSString const * kTriggerChord;
extern NSString const * kTriggerAudioFrame;


