//
//  NameMap.m
//  TimbreGroove
//
//  Created by victor on 3/25/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#include <stdio.h>
#include <string.h>
#include "Names.h"

static NSDictionary * g_nameMap = nil;

void ensureNameMapDict()
{
    if( g_nameMap != nil )
        return;
        
    g_nameMap =
    @{
      @"kMoodPeace":  kMoodPeace ,
      @"kMoodHappy":  kMoodHappy ,
      @"kMoodTroubling":  kMoodTroubling ,
      @"kMoodLoony":  kMoodLoony ,
      @"kMoodDark":  kMoodDark ,
      @"kMoodSexy":  kMoodSexy ,
      
      
      @"kParamMasterVolume":  kParamMasterVolume ,
      @"kParamTempo":  kParamTempo ,
      @"kParamMIDINote":  kParamMIDINote ,
      @"kParamMIDINoteON":  kParamMIDINoteON ,
      @"kParamMIDINoteOFF":  kParamMIDINoteOFF ,
      @"kParamRandomNote":  kParamRandomNote ,
      @"kParamPitch":  kParamPitch ,
      
      @"kParamChannel":  kParamChannel ,
      @"kParamChannelVolume":  kParamChannelVolume ,
      
      @"kParamEQLowPassEnable":  kParamEQLowPassEnable ,
      @"kParamEQParametricEnable":  kParamEQParametricEnable ,
      @"kParamEQHiPassEnable":  kParamEQHiPassEnable ,
      
      @"kParamEQLowCutoff":  kParamEQLowCutoff ,
      @"kParamEQLowResonance":  kParamEQLowResonance ,
      @"kParamEQMidCenterFrequency":  kParamEQMidCenterFrequency ,
      @"kParamEQMidBandwidth":  kParamEQMidBandwidth ,
      @"kParamEQMidGain":  kParamEQMidGain ,
      @"kParamEQHighCutoff=":  kParamEQHighCutoff ,
      @"kParamEQHighResonance":  kParamEQHighResonance ,
      
      @"kParamAudioFrameCapture":  kParamAudioFrameCapture ,
      
      @"kParamInstrumentP1":  kParamInstrumentP1 ,
      @"kParamInstrumentP2":  kParamInstrumentP2 ,
      @"kParamInstrumentP3":  kParamInstrumentP3 ,
      @"kParamInstrumentP4":  kParamInstrumentP4 ,
      @"kParamInstrumentP5":  kParamInstrumentP5 ,
      @"kParamInstrumentP6":  kParamInstrumentP6 ,
      @"kParamInstrumentP7":  kParamInstrumentP7 ,
      @"kParamInstrumentP8":  kParamInstrumentP8 ,
      
      @"kParamColor":  kParamColor ,
      @"kParamPlacement":  kParamPlacement ,
      @"kParamScale":  kParamScale ,
      @"kParamShape":  kParamShape ,
      @"kParamPositionX":  kParamPositionX ,
      @"kParamPositionY":  kParamPositionY ,
      @"kParamPositionZ":  kParamPositionZ ,
      @"kParamRotation":  kParamRotation ,
      @"kParamRotationX":  kParamRotationX ,
      @"kParamRotationY":  kParamRotationY ,
      @"kParamRotationZ":  kParamRotationZ ,
      @"kParamCameraRotationX":  kParamCameraRotationX ,
      @"kParamCameraRotationY":  kParamCameraRotationY ,
      @"kParamCameraRotationZ":  kParamCameraRotationZ ,
      @"kParamCameraZ":  kParamCameraZ ,
      @"kParamSceneAnimation": kParamSceneAnimation,
      @"kParamJointPosition": kParamJointPosition,
      @"kParamCameraReset": kParamCameraReset,
      
      @"kParamLightX": kParamLightX,
      @"kParamLightY": kParamLightY,
      @"kParamLightZ": kParamLightZ,
      @"kParamLightRotationX": kParamLightRotationX,
      @"kParamLightRotationY": kParamLightRotationY,
      @"kParamLightRotationZ": kParamLightRotationZ,      
      @"kParamLightIntensity": kParamLightIntensity,
      @"kParamLightReset": kParamLightReset,
      @"kParamLightWidth": kParamLightWidth,
      @"kParamLightDropoff": kParamLightDropoff,
      
      @"kParamNewElement":  kParamNewElement ,
      
      @"kTriggerVPad1":  kTriggerVPad1 ,
      @"kTriggerVPad2":  kTriggerVPad2 ,
      @"kTriggerVPad3":  kTriggerVPad3 ,
      @"kTriggerVPad4":  kTriggerVPad4 ,
      @"kTriggerVPad5":  kTriggerVPad5 ,
      
      @"kTriggerTimer":  kTriggerTimer ,
      @"kTriggerUpdate":  kTriggerUpdate ,
      @"kTriggerTick":  kTriggerTick ,
      
      @"kTriggerTapPos":  kTriggerTapPos ,
      @"kTriggerTap1":  kTriggerTap1 ,
      @"kTriggerTap2":  kTriggerTap2 ,
      @"kTriggerTap3":  kTriggerTap3 ,
      @"kTriggerDblTap":  kTriggerDblTap ,
      
      @"kTriggerPanX":  kTriggerPanX ,
      @"kTriggerPanY":  kTriggerPanY ,
      @"kTriggerPanX2":  kTriggerPanX2 ,
      @"kTriggerPanY2":  kTriggerPanY2 ,
      @"kTriggerPanDone": kTriggerPanDone,
      
      @"kTriggerTweakX": kTriggerTweakX,
      @"kTriggerTweakY": kTriggerTweakY,
      @"kTriggerDragPos":  kTriggerDragPos ,
      @"kTriggerDrag1":  kTriggerDrag1 ,
      @"kTriggerDrag2":  kTriggerDrag2 ,
      @"kTriggerDrag3":  kTriggerDrag3 ,
      @"kTriggerDirection":  kTriggerDirection ,
      @"kTriggerRotate":  kTriggerRotate ,
      @"kTriggerPinch":  kTriggerPinch ,
      @"kTriggerHold1":  kTriggerHold1 ,
      @"kTriggerHold2":  kTriggerHold2 ,
      @"kTriggerHoldAndDrag":  kTriggerHoldAndDrag ,
      @"kTriggerHoldAndTap":  kTriggerHoldAndTap ,
      @"kTriggerMainSlider":  kTriggerMainSlider ,
      @"kTriggerPlayButton": kTriggerPlayButton,
      
      @"kTriggerDynamicPeak":  kTriggerDynamicPeak ,
      @"kTriggerDynamicHold":  kTriggerDynamicHold ,
      @"kTriggerFrequencyPeak":  kTriggerFrequencyPeak ,
      @"kTriggerBeat":  kTriggerBeat ,
      @"kTriggerNote":  kTriggerNote ,
      @"kTriggerChord":  kTriggerChord ,
      @"kTriggerAudioFrame":  kTriggerAudioFrame 
      };
}

NSString const * textNameForkName( NSString const * kName )
{
    ensureNameMapDict();
    
    NSString * retStr = g_nameMap[kName];
    return retStr ? retStr : kName;
}