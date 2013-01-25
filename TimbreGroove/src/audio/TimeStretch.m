//
//  TimeStretch.m
//  TimbreGroove
//
//  Created by victor on 1/24/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "TimeStretch.h"
#import "fmod_helper.h"
#import "SoundMan.h"
#import "Sound.h"

#include "Dirac.h"

/* ****************************************************************************
 Set up some handy constants
 **************************************************************************** */
const float div8 = 0.0078125f;			//1./pow(2., 8.-1.);
const double div16 = 0.00003051757812;	//1./pow(2., 16.-1.);
const double div32 = 0.00000000046566;	//1./pow(2., 32.-1.);

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/* ****************************************************************************
 This is the struct that holds state variables that our callback needs. In
 your program you will want to replace this by a pointer to "this" in order
 to access your instance methods and member variables
 **************************************************************************** */
typedef struct {
	unsigned int sReadPosition, sFileNumFrames;
	int sNumChannels, sNumBits;
	FMOD_SOUND *sSound;
} userDataStruct;


/* ****************************************************************************
 This converts the raw format from the decoded file to the float format that
 Dirac expects.
 **************************************************************************** */
static void intToFloat(float *dest, void *src, long size, int wordlength)
{
	long wordlengthInBytes = wordlength / 8;
	long numElementsInBuffer = size / wordlengthInBytes;
	long i;
	switch (wordlength) {
		case 8:
		{
			signed char *v = (signed char *)src;
			for ( i = 0; i < numElementsInBuffer; i++)
				dest[i]=(float)v[i] * div8;
		}
			break;
		case 16:
		{
			signed short *v = (signed short *)src;
			for ( i = 0; i < numElementsInBuffer; i++) {
				dest[i]=(float)v[i] * div16;
			}
		}
			break;
		case 24:
		{
			unsigned char *v = (unsigned char *)src;
			long c = 0;
			for ( i = 0; i < numElementsInBuffer; i++)	{
				int32_t value = 0;
				unsigned char *valuePtr = (unsigned char *)&value;
                
				valuePtr[0] = 0;
				valuePtr[1] = v[c]; c++;
				valuePtr[2] = v[c]; c++;
				valuePtr[3] = v[c]; c++;
				
				dest[i]=(double)value * div32;
			}
		}
			break;
		case 32:
		{
			printf("!!! 32bit files are not fully supported. Trying anyway...\n");
#if 0 /* this correctly plays 32 bit AIFF files but not WAV. Byte swapping bug in FMOD? */
			unsigned char *v = (unsigned char *)src;
			long c = 0;
			for (long i = 0; i < numElementsInBuffer; i++) {
				int32_t value = 0;
				unsigned char *valuePtr = (unsigned char *)&value;
				
				valuePtr[3] = v[c]; c++;
				valuePtr[2] = v[c]; c++;
				valuePtr[1] = v[c]; c++;
				valuePtr[0] = v[c]; c++;
				
				dest[i]=(double)value * div32;
			}
#else /* this correctly plays 32bit WAV files but not AIFF. Byte swapping bug in FMOD? */
			
			int32_t *v = (int32_t *)src;
			for ( i = 0; i < numElementsInBuffer; i++) {
				dest[i]=(double)v[i] * div32;
			}
#endif
			
		}
			break;
		default:
			break;
	}
}

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* ****************************************************************************
 Reads a chunk of raw audio from the FMOD sound. If the read access was
 successful we convert the data to float
 **************************************************************************** */
int readFromSound(float *targetBuffer,
                  unsigned int startFrame,
                  unsigned int numFrames,
                  FMOD_SOUND *sound,
                  int numBits,
                  int numChannels)
{
	void  *data1 = NULL;
	void  *data2 = NULL;
	unsigned int length1;
	unsigned int length2;
	
	int ret = -1;
	
	int framesToBytes = numChannels * numBits / 8;
    
	// lock the buffer
    FMOD_Sound_Lock(sound, startFrame * framesToBytes, numFrames * framesToBytes, &data1, &data2, &length1, &length2);
	
	if (data1)
		intToFloat(targetBuffer, data1, length1, numBits);
    
	// unlock the buffer once you're done
    FMOD_Sound_Unlock(sound, data1, data2, length1, length2);
	return ret;
}

/* ****************************************************************************
 This is the callback function that supplies data from the input stream/file
 when needed by Dirac. The read requests are *always* consecutive, ie. the
 routine will never have to supply data out of order.
 Should return the number of frames read, 0 when EOF, and -1 on error.
 **************************************************************************** */
long diracDataProviderCallback(float *chdata, long numFrames, void *userData)
{
	// The userData parameter can be used to pass information about the caller (for example, "this") to
	// the callback so it can manage its audio streams.
	
	if (!chdata)	return 0;
    
	userDataStruct *state = (userDataStruct*)userData;
	if (!state)	return 0;
    
	FMOD_SOUND *mySound = state->sSound;
	
	
	// demonstrates how to loop our sound seamlessly when the file is done playing:
	//
	// we have this many frames left before we hit EOF
	unsigned int framesToReadBeforeEndOfFile = 0;
	
	// if our current read position plus the required amount of frames takes us past the end of the file
	if (state->sReadPosition + numFrames > state->sFileNumFrames) {
		
		// we have this many frames left until EOF
		framesToReadBeforeEndOfFile = state->sFileNumFrames - state->sReadPosition;
		
		// read the remaining frames until EOF
		readFromSound( chdata,
                       state->sReadPosition,
                       framesToReadBeforeEndOfFile,
                       mySound,
                       state->sNumBits,
                       state->sNumChannels);
		
		// rewind the file
		state->sReadPosition = 0;
		
		// remove the amount we just read from the amount that we actually want
		numFrames -= framesToReadBeforeEndOfFile;
	}
	
	// here we read the second part of the buffer (in case we hit EOF along the way), or just a chunk of audio from the file (in case we have not encountered EOF yet)
	readFromSound( chdata + framesToReadBeforeEndOfFile*state->sNumChannels,
                   state->sReadPosition,
                   numFrames,
                   mySound,
                   state->sNumBits,
                   state->sNumChannels);
    
	state->sReadPosition += numFrames;
	
	return numFrames;
	
}


//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* ****************************************************************************
 This is our custom dsp callback as implemented by the FMOD example
 dsp_custom.
 **************************************************************************** */
FMOD_RESULT F_CALLBACK myDSPCallback(FMOD_DSP_STATE *dsp_state,
                                     float *inbuffer,
                                     float *outbuffer,
                                     unsigned int length,
                                     int inchannels,
                                     int outchannels)
{
    unsigned int userdata;
    char name[256];
    FMOD_DSP *thisdsp = (FMOD_DSP *)dsp_state->instance;
    
	int ret = kDiracErrorNoErr;
	
    /*
     This redundant call just shows using the instance parameter of FMOD_DSP_STATE and using it to
     call a DSP information function.
     */
    FMOD_DSP_GetInfo(thisdsp, name, 0, 0, 0, 0);
    
	// userData points to our Dirac instance
    FMOD_DSP_GetUserData(thisdsp, (void **)&userdata);
	
	if (!userdata)
		return FMOD_ERR_NOTREADY;
	
	ret = DiracProcessInterleaved(outbuffer, length, (void*)userdata);
	
	switch (ret) {
		case kDiracErrorDemoTimeoutReached:
			printf("!!! Dirac Evaluation has reached its demo timeout\n\tSwitching to BYPASS\n");
            FMOD_DSP_SetBypass(thisdsp, true);
			break;
		default:
			break;
	}
	
    return FMOD_OK;
} 

@interface TimeStretch () {
	userDataStruct state;
    FMOD_DSP * _dsp;
}
@end

@implementation TimeStretch


-(void)setBypass:(bool)bypass
{
    FMOD_BOOL doBypass = (FMOD_BOOL)bypass;
    FMOD_RESULT result = FMOD_DSP_SetBypass(_dsp, doBypass);
    ERRCHECK(result);
}

-(bool)bypass
{
    FMOD_BOOL doBypass;
    FMOD_RESULT result = FMOD_DSP_GetBypass(_dsp, &doBypass);
    ERRCHECK(result);
    return doBypass;
    
}
-(void)addToSound:(Sound *)soundObj
      timeStretch:(float)time
        semitones:(float)semitones
{
    FMOD_SOUND * sound = (FMOD_SOUND *)soundObj.nativeSound;
	state.sReadPosition = 0;
	state.sSound = sound;
    int sampleRate;
    FMOD_RESULT result;
	
    FMOD_SYSTEM * system = [[SoundMan sharedInstance] getSystem];
	// get the output (=processing) sample rate from the system
	// actually, we should use the file's sample rate, but I'm not sure if there is a call for that in FMOD
    result = FMOD_System_GetSoftwareFormat(system, &sampleRate, 0, 0, 0, 0, 0);
    ERRCHECK(result);
    
	// obtain the length of the sound in sample frames (needed to loop the sound properly)
    result = FMOD_Sound_GetLength(sound, &state.sFileNumFrames, FMOD_TIMEUNIT_PCM);
	ERRCHECK(result);
    
	// get the number of channels and number of bits. Needed to obtain the correct seek position in the file when using Sound::lock
    result = FMOD_Sound_GetFormat(sound, NULL, NULL, &state.sNumChannels, &state.sNumBits);
	ERRCHECK(result);
	
    sampleRate = 44100;
    
	// create our Dirac instance. We use the fastest possible setting for the Dirac core API here
	// If you
	void *dirac = DiracCreateInterleaved(kDiracLambdaPreview,
                                         kDiracQualityPreview,
                                         state.sNumChannels,
                                         sampleRate,
                                         &diracDataProviderCallback,
                                         (void*)&state);
	if (!dirac) {
        NSLog(@"!! ERROR !!\n\n\tCould not create DIRAC instance\n\tCheck number of channels and sample rate!\n");
		exit(-1);
	}
	
	// Here we set our time stretch an pitch shift values
	//float time      = 1.25f;					// 125% length
	float pitch = semitones; // pow(2.f, semitones/12.f);		// pitch shift (0 semitones)
    
    // Pass the values to our DIRAC instance
	DiracSetProperty(kDiracPropertyTimeFactor, time, dirac);
	DiracSetProperty(kDiracPropertyPitchFactor, pitch, dirac);
	
	// start playback
    /*
    result = system->playSound(FMOD_CHANNEL_FREE, sound, false, &channel);
    ERRCHECK(result);
     */

    {
        FMOD_DSP_DESCRIPTION  dspdesc;
        
        memset(&dspdesc, 0, sizeof(FMOD_DSP_DESCRIPTION));
        
        strcpy(dspdesc.name, "TG/Dirac Time Stretch Unit");
        dspdesc.channels     = state.sNumChannels;  // 0 = whatever comes in, else specify.
        dspdesc.read         = myDSPCallback;
        dspdesc.userdata     = (void *)dirac;
        
        result = FMOD_System_CreateDSP(system, &dspdesc, &_dsp);
        ERRCHECK(result);
    }
    
    FMOD_CHANNEL * channel = (FMOD_CHANNEL *)soundObj.nativeChannel;
    result = FMOD_Channel_AddDSP(channel, _dsp, NULL);
    ERRCHECK(result);
        
}
@end
