//
//  Oscillator.m
//  TimbreGroove
//
//  Created by victor on 3/18/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "ToneGenerator.h"
#import "SoundSystem.h"
#import "NoiseGen.h"
#import "Parameter.h"

@interface Oscillator : ToneGenerator
@property (nonatomic,strong) NSString * waveType;
@end

typedef enum _OscWaveType {
    OWT_Sine = 1,
    OWT_Square = 2,
    OWT_Saw = 4
} OscWaveType;

typedef struct _OscillatorRef
{
    OscWaveType waveType;
    float frequency;
    int cmd;
	double startingFrameCount;
    unsigned int noiseFactor;
    unsigned int noiseCount;
    NoiseGen ng;
} OscillatorRef;


typedef Float32 FrameType;

OSStatus OscillatorRenderProc(void *inRefCon,
                              AudioUnitRenderActionFlags *ioActionFlags,
                              const AudioTimeStamp *inTimeStamp,
                              UInt32 inBusNumber,
                              UInt32 inNumberFrames,
                              AudioBufferList * ioData)
{
    
	OscillatorRef *ref = (OscillatorRef*)inRefCon;
	
    FrameType *left  = (FrameType*)ioData->mBuffers[0].mData;
    FrameType *right = (FrameType*)ioData->mBuffers[1].mData;
    int frame = 0;
    
    if( ref->frequency )
    {
        double j = ref->startingFrameCount;
        double cycleLength = 44100.0 / ref->frequency;
        bool bSine = ref->waveType == OWT_Sine;
        bool bSquare = ref->waveType == OWT_Square;
        bool bRampUp   = ref->cmd == kMIDIMessage_NoteOn;
        bool bRampDown = ref->cmd == kMIDIMessage_NoteOff;
        for (frame = 0; frame < inNumberFrames; ++frame)
        {
            float f;
            
            if( (ref->noiseFactor > 0) && (--ref->noiseCount == 0) )
            {
                ref->noiseCount = ref->noiseFactor;
                f = nextNoiseValue(&ref->ng);
            }
            else
            {
                if( bSine )
                    f = (float)(sin (2.0 * M_PI * (j / cycleLength)));
                else if( bSquare )
                    f = j < cycleLength/2.0 ? -1.0 : 1.0;
                else // saw
                    f = (float)( ((j / cycleLength) * 2.0) - 1.0 );
                
                if( bRampUp )
                    f *= (float)frame / (float)inNumberFrames;
                else if( bRampDown )
                    f *= 1.0 - ((float)frame / (float)inNumberFrames);
            }
            
            left[frame] = right[frame] = f;
            
            j += 1.0;
            if (j > cycleLength)
                j -= cycleLength;
        }
        
        ref->startingFrameCount = j;
        if( bRampDown )
            ref->frequency = 0;
        ref->cmd = 0;
    }
    else
    {
        FrameType fzero = (FrameType)0;
        int zero = *(int *)&fzero;
        memset(left,  zero, ioData->mBuffers[0].mDataByteSize);
        memset(right, zero, ioData->mBuffers[0].mDataByteSize);
    }
	return noErr;
}


@implementation Oscillator {
    OscillatorRef _oref;
    bool _released;
}

-(void)dealloc
{
    [self detach];
    TGLog(LLObjLifetime, @"%@ released",self);
}

-(void)setWaveType:(NSString *)waveType
{
    _waveType = waveType;
    // These are set in config.plist
    if( [_waveType isEqualToString:@"Sine"] )
        _oref.waveType = OWT_Sine;
    else if( [_waveType isEqualToString:@"Square"] )
        _oref.waveType = OWT_Square;
    else if( [_waveType isEqualToString:@"Saw"] )
        _oref.waveType = OWT_Saw;
}

-(MIDISendBlock)midiRenderProc
{
    return ^ OSStatus( UInt32 inStatus, UInt32 inData1, UInt32 inData2, UInt32 inOffsetSampleFrame) {
        Byte midiCommand = inStatus >> 4;
        
        if( midiCommand == kMIDIMessage_NoteOn )
        {
            _oref.startingFrameCount = 0;
            _oref.cmd = midiCommand;
            _oref.frequency = 8.1758 * pow(2,(double)inData1/12.0);
            TGLog(LLMidiStuff, @"Oscillator: Note: %d  Frequency:%f type:%@",inData1,_oref.frequency,_waveType);
        }
        else if( midiCommand == kMIDIMessage_NoteOff )
        {
            _oref.cmd = midiCommand;
//            _oref.frequency = 0;
            TGLog(LLMidiStuff, @"Oscillator: Note OFF: %d  Frequency:%f type:%@",inData1,_oref.frequency,_waveType);
        }
        else
        {
            TGLog(LLMidiStuff, @"What? MIDI: %d",midiCommand);
            
        }
        return noErr;
    };
    
}

-(void)didAttachToGraph:(SoundSystem *)ss
{
    [super didAttachToGraph:ss];
    
    _released = false;
    
    initNoise(&_oref.ng);
    
	AURenderCallbackStruct input;
	input.inputProc = OscillatorRenderProc;
	input.inputProcRefCon = &_oref;
	CheckError(AudioUnitSetProperty(self.mixerAU,
									kAudioUnitProperty_SetRenderCallback,
									kAudioUnitScope_Input,
									self.channel,
									&input,
									sizeof(input)),
			   "Set render callback failed");
}

-(void)detach
{
    if( _released )
        return;
    
	AURenderCallbackStruct input;
	input.inputProc = NULL;
	input.inputProcRefCon = NULL;
	CheckError(AudioUnitSetProperty(self.mixerAU,
									kAudioUnitProperty_SetRenderCallback,
									kAudioUnitScope_Input,
									self.channel,
									&input,
									sizeof(input)),
			   "Remove render callback failed");
    _released = true;
}

-(void)getParameters:(NSMutableDictionary *)parameters
{
    [super getParameters:parameters];
    
    parameters[@"OscNoiseFactor"] = [Parameter withBlock:^(int value) {
        _oref.noiseFactor = (value * value) * 100;
        TGLog(LLMidiStuff, @"Noise factor: %d",_oref.noiseFactor);
    }];
}

@end
