//
//  Mixer+Parameters.m
//  TimbreGroove
//
//  Created by victor on 2/14/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//
#import "Mixer.h"
#import "Mixer+Parameters.h"

const float kBottomOfOctiveRange = 0.05;
const float kTopOfOctiveRange = 5.0;

@implementation Mixer (Parameters)

@dynamic selectedEQBand;
@dynamic mixerOutputGain;

-(void)setSelectedEQBand:(eqBands)selectedEQBand
{
    _selectedEQBand = selectedEQBand;
}

-(eqBands)selectedEQBand
{
    return _selectedEQBand;
}

- (void) setMixerOutputGain: (AudioUnitParameterValue) newGain
{
    OSStatus result = AudioUnitSetParameter (
                                             _mixerUnit,
                                             kMultiChannelMixerParam_Volume,
                                             kAudioUnitScope_Output,
                                             0,
                                             newGain,
                                             0
                                             );
    
    CheckError(result,"Unable to set output gain.");
    
    _mixerOutputGain = newGain;
}

-(AudioUnitParameterValue)mixerOutputGain
{
    return _mixerOutputGain;
}

-(void) setEqBandwidth:(AudioUnitParameterValue)eqBandwidth
{
    // 0.05 through 5.0 octaves
    AudioUnitParameterValue nativeValue = (eqBandwidth * (kTopOfOctiveRange-kBottomOfOctiveRange)) +
    (eqBandwidth * kBottomOfOctiveRange);
    //NSLog(@"eq bw set to %f <- %f", nativeValue, eqBandwidth);
    OSStatus result = AudioUnitSetParameter (
                                             _masterEQUnit,
                                             kAUNBandEQParam_Bandwidth + _selectedEQBand,
                                             kAudioUnitScope_Global,
                                             0,
                                             nativeValue,
                                             0
                                             );
    
    CheckError(result,"Unable to set eq HiBandwidth.");
    
    _eqValues[_selectedEQBand][kEQBandwidthIndex] = eqBandwidth;
}

-(AudioUnitParameterValue)eqBandwidth
{
    return _eqValues[_selectedEQBand][kEQBandwidthIndex];
}

-(void) calcEQBandLow:(float *)lo andHigh:(float *)hi
{
    const float kLowestFreq = 20.0;
    float highestFreq = _graphSampleRate / 2.0;
    float singleEQBandRange = (highestFreq - kLowestFreq) / kNUM_EQ_BANDS;
    *lo = (singleEQBandRange * _selectedEQBand) + kLowestFreq;
    *hi = *lo + singleEQBandRange;
}

-(void) setEqCenter:(AudioUnitParameterValue)eqCenter
{
    // 20 Hz to < Nyquist freq (sampleRate/2)
    float min, max;
    [self calcEQBandLow:&min andHigh:&max];
    AudioUnitParameterValue nativeValue = (eqCenter * (max-min)) + (min * eqCenter);
    //NSLog(@"eq center to %f <- %f", nativeValue, eqCenter);
    OSStatus result = AudioUnitSetParameter (
                                             _masterEQUnit,
                                             kAUNBandEQParam_Frequency + _selectedEQBand,
                                             kAudioUnitScope_Global,
                                             0,
                                             nativeValue,
                                             0
                                             );
    
    CheckError(result,"Unable to set eq HiCenter.");
    
    _eqValues[_selectedEQBand][kEQCenterIndex] = eqCenter;
}

-(AudioUnitParameterValue)eqCenter
{
    return _eqValues[_selectedEQBand][kEQCenterIndex];
}

-(void) setEqPeak:(AudioUnitParameterValue)eqPeak
{
    // –96 through +24 dB
    float min = -96;
    float max = 24;
    // TODO: I think this should be log() something other than "linear"
    AudioUnitParameterValue nativeValue = (eqPeak * (max-min)) + (min * eqPeak);
    //NSLog(@"eq[%d] peak to %f <- %f", _selectedEQBand, nativeValue, eqPeak);
    
    //
    // 6db = (x * (24 + 96)) - 96;
    // 6 + 96 = x * 130;
    // 102 / 130 = x
    //
    OSStatus result = AudioUnitSetParameter (
                                             _masterEQUnit,
                                             kAUNBandEQParam_Gain + _selectedEQBand,
                                             kAudioUnitScope_Global,
                                             0,
                                             nativeValue,
                                             0
                                             );
    
    CheckError(result,"Unable to set eq peak.");
    
    _eqValues[_selectedEQBand][kEQPeakIndex] = eqPeak;
}

-(AudioUnitParameterValue)eqPeak
{
    return _eqValues[_selectedEQBand][kEQPeakIndex];
}
@end
