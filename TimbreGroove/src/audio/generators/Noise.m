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

@interface Noise : NSObject <ToneGeneratorProtocol>

@end


typedef struct _NoiseRef
{
    NoiseGen gen;
    float frequency;
    int cmd;
	double startingFrameCount;
} NoiseRef;

typedef Float32 FrameType;


OSStatus NoiseRenderProc(void *inRefCon,
                         AudioUnitRenderActionFlags *ioActionFlags,
                         const AudioTimeStamp *inTimeStamp,
                         UInt32 inBusNumber,
                         UInt32 inNumberFrames,
                         AudioBufferList * ioData)
{
	NoiseRef *ref = (NoiseRef*)inRefCon;
	
    FrameType *left  = (FrameType*)ioData->mBuffers[0].mData;
    FrameType *right = (FrameType*)ioData->mBuffers[1].mData;
    int frame = 0;
    
    if( ref->frequency )
    {
        bool bRampUp   = ref->cmd == kMIDIMessage_NoteOn;
        bool bRampDown = ref->cmd == kMIDIMessage_NoteOff;
        for (frame = 0; frame < inNumberFrames; ++frame)
        {
            float f = nextNoiseValue(&ref->gen);
            
            if( bRampUp )
                f *= (float)frame / (float)inNumberFrames;
            else if( bRampDown )
                f *= 1.0 - ((float)frame / (float)inNumberFrames);
            
            left[frame] = right[frame] = f;
            
        }
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


@implementation Noise {
    __weak ToneGeneratorProxy * _proxy;
    NoiseRef _nref;
    bool _released;
}

-(void)dealloc
{
    [self detach];
    TGLog(LLObjLifetime, @"%@ released",self);
}

-(void)detach
{
    [self releaseRenderProc];
}

-(MIDISendBlock)renderProcForToneGenerator:(ToneGeneratorProxy *)generatorProxy
{
    _proxy = generatorProxy;
    _released = false;
    
    initNoise(&_nref.gen);
    
	AURenderCallbackStruct input;
	input.inputProc = NoiseRenderProc;
	input.inputProcRefCon = &_nref;
	CheckError(AudioUnitSetProperty(_proxy.au,
									kAudioUnitProperty_SetRenderCallback,
									kAudioUnitScope_Input,
									_proxy.channel,
									&input,
									sizeof(input)),
			   "Set render callback failed");

    return ^ OSStatus( UInt32 inStatus, UInt32 inData1, UInt32 inData2, UInt32 inOffsetSampleFrame) {
        Byte midiCommand = inStatus >> 4;
        
        TGLog(LLMidiStuff, @"NOISE MIDI: %d",midiCommand);
        
        if( midiCommand == kMIDIMessage_NoteOn )
        {
            _nref.startingFrameCount = 0;
            _nref.cmd = midiCommand;
            _nref.frequency = 8.1758 * pow(2,(double)inData1/12.0);
        }
        else if( midiCommand == kMIDIMessage_NoteOff )
        {
            _nref.cmd = midiCommand;
            _nref.frequency = 0;
        }
        else
        {
            TGLog(LLMidiStuff, @"What MIDI: %d",midiCommand);
            
        }
        return noErr;
    };
    
}

-(void)releaseRenderProc
{
    if( _released )
        return;
    
	AURenderCallbackStruct input;
	input.inputProc = NULL;
	input.inputProcRefCon = NULL;
	CheckError(AudioUnitSetProperty(_proxy.au,
									kAudioUnitProperty_SetRenderCallback,
									kAudioUnitScope_Input,
									_proxy.channel,
									&input,
									sizeof(input)),
			   "Remove render callback failed");
    
    _released = true;
}

-(void)getParameters:(NSMutableDictionary *)parameters
{
    
}
-(void)triggersChanged:(Scene *)scene
{
    
}

-(AURenderCallback) getCallback
{
    return NoiseRenderProc;
}
@end
