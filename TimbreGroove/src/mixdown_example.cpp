//
//  mixdown_example.cpp
//  TimbreGroove
//
//  Created by victor on 12/27/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#include "fmod.h"
#include "fmod.hpp"

typedef unsigned __int64 Uint64;

class Uint64P
{
public:
    Uint64P(Uint64 val = 0)
    : mHi(unsigned int(val >> 32)), mLo(unsigned int(val & 0xFFFFFFFF))
    { }
    
    Uint64 value() const
    {
        return (Uint64(mHi) << 32) + mLo;
    }
    
    void operator+=(const Uint64P &rhs)
    {
        FMOD_64BIT_ADD(mHi, mLo, rhs.mHi, rhs.mLo);
    }
    
    unsigned int mHi;
    unsigned int mLo;
};


void do_example()
{
    FMOD_SYSTEM*    h_audio_sys;        //handle to system
    FMOD_SOUND*     h_sound_now;        //handle to sound currently playing
    FMOD_SOUND*     h_sound_prev(0);    //handle to previous sound
    FMOD_CHANNEL*   h_channel;          //handle to channel
    unsigned int    min_delay;          //delay
    double          min_delay_s;        //delay in seconds
    FMOD_RESULT     result;             //code of any error messages
    Uint64P         start_time;         //start time of the recording
    double          start_time_s;       //start time in seconds
    Uint64P         choice_time;        //time when we setup the next arrangement
    Uint64P         end_time;           //end time of current arrangement (and start time of next)
    double          elapsed_time_s;     //elapsed time in seconds
    unsigned int    sample_rate(44100)  //the sample rate
    double          length_s(30);       //length of the mixdown

    //initalize the system----------------------------------------------------------------------
    // create a System object and initialize
    result = FMOD_System_Create(&h_audio_sys);

    //set the output to non-realtime record
    result = FMOD_System_SetOutput(h_audio_sys, FMOD_OUTPUTTYPE_WAVWRITER_NRT);

    //set the output sample rate
    result = FMOD_System_SetSoftwareFormat(h_audio_sys, sample_rate, FMOD_SOUND_FORMAT_PCM16, 2, 6, FMOD_DSP_RESAMPLER_LINEAR);

    //init the system (and specify name of output wav file)
    result = FMOD_System_Init(h_audio_sys, 100,  FMOD_INIT_STREAM_FROM_UPDATE, file_name);

    //set volume
    FMOD_CHANNELGROUP* channel_group;
    FMOD_System_GetMasterChannelGroup(h_audio_sys, &channel_group);
    FMOD_ChannelGroup_SetVolume(channel_group, 1);
    //------------------------------------------------------------------------------------------

    //load sound -------------------------------------------------------------------------------
    result = FMOD_System_CreateStream(h_audio_sys, "music.wav", FMOD_SOFTWARE, 0, &h_sound_now);
    //------------------------------------------------------------------------------------------

    //set delay using buffer size --------------------------------------------------------------
    result = FMOD_System_GetDSPBufferSize(h_audio_sys, &min_delay, 0);
    min_delay *= 2;
    min_delay_s = ((double)min_delay) / ((double)sample_rate);
    //------------------------------------------------------------------------------------------

    //put sound in channel in a paused state ---------------------------------------------------
    result = FMOD_System_PlaySound(h_audio_sys, FMOD_CHANNEL_FREE, h_sound_now, true, &h_channel);

    //------------------------------------------------------------------------------------------

    //get the start_time of the recording & add small delay to it ------------------------------
    result = FMOD_Channel_GetDelay(h_channel,  FMOD_DELAYTYPE_DSPCLOCK_START, &start_time.mHi, &start_time.mLo);
    start_time += min_delay;
    start_time_s = start_time / sample_rate;
    //------------------------------------------------------------------------------------------

    //set the start time of the channel and unpause it------------------------------------------
    result = FMOD_Channel_SetDelay(h_channel, FMOD_DELAYTYPE_DSPCLOCK_START, start_time.mHi, start_time.mLo);
    result = FMOD_Channel_SetPaused(h_channel, false);
    //------------------------------------------------------------------------------------------

    //calculate when we need to setup the next sample & also when we need to start it -----
    end_time = start_time;
    end_time += get_arr_length_pcm(sample_rate);
    choice_time = end_time;
    choice_time -= min_delay;
    //------------------------------------------------------------------------------------------

    bool finish_up(false);          //true if the sample we are playing should be the last one
    bool stop(false);               //true if we need to stop recording

    while (!stop)
    {
        //get current dsp time -----------------------------------------------------------------
        Uint64P dsp_time;
        result = FMOD_System_GetDSPClock(h_audio_sys, &dsp_time.mHi, &dsp_time.mLo);
        //--------------------------------------------------------------------------------------
        
        //get current time in seconds ----------------------------------------------------------
        elapsed_time_s = (dsp_time / sample_rate) - start_time_s;
        //--------------------------------------------------------------------------------------
        
        //setup the next sample if necessary-----------------------------------------------
        if ( !finish_up && ( (dsp_time.mHi >= choice_time.mHi) && (dsp_time.mLo >= choice_time.mLo) ))
        {
            if ( (elapsed_time_s + min_delay_s) >= length_s )  //is this the last sample to be played?
            {
                if (h_sound_prev )
                {
                    result = FMOD_Sound_Release(h_sound_prev);
                }
                finish_up = true;
            }
            else
            {
                //free any previous sounds -----------------------------------------------------------------
                if (h_sound_prev )
                {
                    result = FMOD_Sound_Release(h_sound_prev);
                }
                //------------------------------------------------------------------------------------------
                
                //store the sound currently playing --------------------------------------------------------
                h_sound_prev = h_sound_now;
                //------------------------------------------------------------------------------------------
                
                //load sound -------------------------------------------------------------------------------
                result = FMOD_System_CreateStream(h_audio_sys, "music.wav", FMOD_SOFTWARE, 0, &h_sound_now);
                //-------------------------------------------------------------------------------------------
                
                //put sound in channel in a paused state ---------------------------------------------------
                result = FMOD_System_PlaySound(h_audio_sys, FMOD_CHANNEL_FREE, h_sound_now, true, &h_channel);
                //------------------------------------------------------------------------------------------
                
                //set the start time of the channel and unpause it------------------------------------------
                start_time = end_time;
                result = FMOD_Channel_SetDelay(h_channel, FMOD_DELAYTYPE_DSPCLOCK_START, start_time.mHi, start_time.mLo);
                result = FMOD_Channel_SetPaused(h_channel, false);
                //------------------------------------------------------------------------------------------
                
                //calculate when we need to setup the next sample & also when we need to start it -----
                end_time = start_time;
                end_time += get_arr_length_pcm(sample_rate);
                choice_time = end_time;
                choice_time -= min_delay;
                //------------------------------------------------------------------------------------------
            }
        }
        //--------------------------------------------------------------------------------------
        
        //if the last sample has finished playing than exit--------------------------------
        if ( finish_up && ( (dsp_time.mHi >= end_time.mHi) && (dsp_time.mLo >= end_time.mLo) ))
            stop = true;
            //--------------------------------------------------------------------------------------
            
            //update the audio system---------------------------------------------------------------
            result = FMOD_System_Update(h_audio_sys);
        //--------------------------------------------------------------------------------------
    }

    //-release sound and audio system ----------------------------------------------------------
    FMOD_Sound_Release(h_sound_now);
    FMOD_System_Release(h_audio_sys);
    //------------------------------------------------------------------------------------------
}