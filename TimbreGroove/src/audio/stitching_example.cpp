//
//  stitching_example.cpp
//  TimbreGroove
//
//  Created by victor on 12/27/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#include <stdio.h>

/*=============================================================================
 Sample-accurate sequencing example
 Copyright (c), Firelight Technologies Pty, Ltd 2008-2009.
 
 An example of sample-accurate sequencing with the Channel::setDelay function
 =============================================================================*/
#include "fmod.hpp"
#include "fmod_errors.h"
//#include <windows.h>
#include <stdio.h>
//#include <conio.h>

// define this to write the output to setDelay_output.wav for debugging purposes
//#define USE_WAVWRITER

/************ Testing functions ************/
void ERRCHECK(FMOD_RESULT result)
{
    if (result != FMOD_OK)
    {
        printf("FMOD error! (%d) %s\n", result, FMOD_ErrorString(result));
        _getch();
        exit(-1);
    }
}

void ERRCHECK_CHANNEL(FMOD_RESULT result)
{
    if (result != FMOD_OK && result != FMOD_ERR_INVALID_HANDLE
        && result != FMOD_ERR_CHANNEL_STOLEN)
    {
        printf("FMOD error! (%d) %s\n", result, FMOD_ErrorString(result));
        _getch();
        exit(-1);
    }
}


// simple 64-bit int handling types
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


// This class handles the sample-accurate sequencing
class SoundManager
{
public:
    SoundManager(int numsounds);
    ~SoundManager();
    
    void start();
    void update();
    
    void setPaused(bool paused);
    bool paused() const { return m_paused; }
    
    int getChannelsPlaying();
    
private:
    void scheduleChannel(int i);
    
    FMOD::System* m_system;
    int m_numsounds;
    
    unsigned int m_min_delay;
    int m_outputrate;
    int m_first_index;
    bool m_paused;
    Uint64P m_pause_time;
    
    FMOD::Sound** m_sounds;
    FMOD::Channel** m_channels;
};

SoundManager::SoundManager(int numsounds)
: m_system(0), m_numsounds(numsounds),
m_min_delay(0), m_outputrate(0), m_first_index(0),
m_paused(false), m_sounds(0), m_channels(0)
{
    ERRCHECK(FMOD::System_Create(&m_system));
    
    unsigned int version;
    ERRCHECK(m_system->getVersion(&version));
    
    if (version < FMOD_VERSION)
    {
        printf("Error! You are using an old version of FMOD: %08x."
               " This program requires %08x\n", version, FMOD_VERSION);
        ERRCHECK(FMOD_ERR_INTERNAL);
    }
    
#ifdef USE_WAVWRITER
    {
        const char *output_wav = "setDelay_output.wav";
        
        ERRCHECK(m_system->setOutput(FMOD_OUTPUTTYPE_WAVWRITER));
        
        ERRCHECK(m_system->init(32,
                                FMOD_INIT_NORMAL |
                                FMOD_INIT_SOFTWARE_OCCLUSION |
                                FMOD_INIT_ENABLE_PROFILE,
                                (void *)output_wav));
    }
#else
    ERRCHECK(m_system->init(32,
                            FMOD_INIT_NORMAL |
                            FMOD_INIT_SOFTWARE_OCCLUSION |
                            FMOD_INIT_ENABLE_PROFILE,
                            0));
#endif
    
    m_sounds = new FMOD::Sound* [m_numsounds];
    m_channels = new FMOD::Channel* [m_numsounds];
    
    const char *filename = "c_tiny.wav";
    for(int i = 0; i < m_numsounds; ++ i)
    {
        ERRCHECK(m_system->createSound(filename, FMOD_SOFTWARE, 0, &m_sounds[i]));
        m_channels[i] = 0;
    }
    
    ERRCHECK(m_system->getDSPBufferSize(&m_min_delay, 0));
    m_min_delay *= 2;
    
    ERRCHECK(m_system->getSoftwareFormat(&m_outputrate, 0, 0, 0, 0, 0));
}

SoundManager::~SoundManager()
{
    delete [] m_sounds;
    delete [] m_channels;
    
    ERRCHECK(m_system->release());
}

void SoundManager::scheduleChannel(int i)
{
    int prev = (i + m_numsounds - 1) % m_numsounds;
    
    Uint64P start_time;
    
    bool playing = false;
    ERRCHECK_CHANNEL(m_channels[prev]->isPlaying(&playing));
    
    if(playing)
    {
        // schedule at the end of the previous channel
        unsigned int length_pcm;
        float frequency;
        
        ERRCHECK(m_channels[prev]->getDelay(FMOD_DELAYTYPE_DSPCLOCK_START,
                                            &start_time.mHi, &start_time.mLo));
        ERRCHECK(m_sounds[prev]->getDefaults(&frequency, 0, 0, 0));
        ERRCHECK(m_sounds[prev]->getLength(&length_pcm, FMOD_TIMEUNIT_PCM));
        
        length_pcm = unsigned int((length_pcm * m_outputrate / frequency) + 0.5f);
        start_time += length_pcm;
    }
    else
    {
        // the previous channel isn't playing; schedule ASAP
        ERRCHECK(m_system->getDSPClock(&start_time.mHi, &start_time.mLo));
        start_time += m_min_delay;
    }
    
    ERRCHECK(m_channels[i]->setDelay(FMOD_DELAYTYPE_DSPCLOCK_START,
                                     start_time.mHi, start_time.mLo));
}

void SoundManager::start()
{
    for(int i = 0; i < m_numsounds; ++ i)
    {
        ERRCHECK(m_system->playSound(FMOD_CHANNEL_FREE, m_sounds[i], true, &m_channels[i]));
    }
    
    m_first_index = 0;
    
    Uint64P start_time;
    
    ERRCHECK(m_channels[0]->getDelay(FMOD_DELAYTYPE_DSPCLOCK_START, &start_time.mHi, &start_time.mLo));
    start_time += m_min_delay;
    ERRCHECK(m_channels[0]->setDelay(FMOD_DELAYTYPE_DSPCLOCK_START, start_time.mHi, start_time.mLo));
    
    for(int i = 1; i < m_numsounds; ++i)
    {
        scheduleChannel(i);
    }
    
    for(int i = 0; i < m_numsounds; ++i)
    {
        ERRCHECK(m_channels[i]->setPaused(false));
    }
}

void SoundManager::update()
{
    ERRCHECK(m_system->update());
    
    if(m_paused)
    {
        return;
    }
    
    // start any channels that have stopped and schedule them at the end of the sequence
    bool playing = false;
    
    ERRCHECK_CHANNEL(m_channels[m_first_index]->isPlaying(&playing));
    
    while(!playing)
    {
        ERRCHECK(m_system->playSound(FMOD_CHANNEL_FREE, m_sounds[m_first_index],
                                     true, &m_channels[m_first_index]));
        
        scheduleChannel(m_first_index);
        
        ERRCHECK(m_channels[m_first_index]->setPaused(false));
        
        m_first_index = (m_first_index + 1) % m_numsounds;
        
        playing = false;
        ERRCHECK_CHANNEL(m_channels[m_first_index]->isPlaying(&playing));
    }
}

void SoundManager::setPaused(bool paused)
{
    if(paused == m_paused)
    {
        return;
    }
    
    m_paused = paused;
    
    if(m_paused)
    {
        ERRCHECK(m_system->getDSPClock(&m_pause_time.mHi, &m_pause_time.mLo));
        m_pause_time += m_min_delay;
        
        for(int i = 0; i < m_numsounds; ++i)
        {
            bool playing = false;
            ERRCHECK_CHANNEL(m_channels[i]->isPlaying(&playing));
            
            if(playing)
            {
                // we use FMOD_DELAYTYPE_DSPCLOCK_PAUSE instead of setPaused to get
                // sample-accurate pausing (so we know exactly when the channel will pause)
                ERRCHECK(m_channels[i]->setDelay(FMOD_DELAYTYPE_DSPCLOCK_PAUSE,
                                                 m_pause_time.mHi, m_pause_time.mLo));
            }
        }
    }
    else
    {
        Uint64P current_time;
        
        ERRCHECK(m_system->getDSPClock(&current_time.mHi, &current_time.mLo));
        current_time += m_min_delay;
        
        // calculate how long it's been since we paused; this is how much we need
        // to offset the delays of all the channels by
        Uint64 delta = current_time.value() - m_pause_time.value();
        
        for(int i = 0; i < m_numsounds; ++i)
        {
            bool playing = false;
            ERRCHECK_CHANNEL(m_channels[i]->isPlaying(&playing));
            
            if(playing)
            {
                Uint64P unpause_time;
                ERRCHECK(m_channels[i]->getDelay(FMOD_DELAYTYPE_DSPCLOCK_START,
                                                 &unpause_time.mHi, &unpause_time.mLo));
                
                unsigned int position;
                float frequency;
                ERRCHECK(m_channels[i]->getPosition(&position, FMOD_TIMEUNIT_PCM));
                ERRCHECK(m_sounds[i]->getDefaults(&frequency, 0, 0, 0));
                
                // get the channel's position in output samples; the channel will start
                // playing from this position as soon as the start time is reached, so
                // we need to offset the start time from the original by this amount
                Uint64 position_output = Uint64((position / frequency * m_outputrate) + 0.5);
                
                unpause_time += delta + position_output;
                
                ERRCHECK(m_channels[i]->setDelay(FMOD_DELAYTYPE_DSPCLOCK_START,
                                                 unpause_time.mHi, unpause_time.mLo));
            }
        }
        
        for(int i = 0; i < m_numsounds; ++i)
        {
            ERRCHECK_CHANNEL(m_channels[i]->setDelay(FMOD_DELAYTYPE_DSPCLOCK_PAUSE,
                                                     0, 0));
            ERRCHECK_CHANNEL(m_channels[i]->setPaused(false));
        }
    }
}

int SoundManager::getChannelsPlaying()
{
    int playingchannels;
    ERRCHECK(m_system->getChannelsPlaying(&playingchannels));
    
    return playingchannels;
}

int main(int argc, char *argv[])
{
    SoundManager soundManager(5);
    
    printf("Start\n");
    
    soundManager.start();
    
    /*
     Main loop.
     */
    int first_index = 0;
    int key = 0;
    
    do
    {
        if (_kbhit())
        {
            key = _getch();
            
            if(key == ' ')
            {
                soundManager.setPaused(!soundManager.paused());
            }
        }
        
        soundManager.update();
        
        printf("Channels playing: %6d, %10s\r",
               soundManager.getChannelsPlaying(),
               soundManager.paused() ? "Paused" : "Unpaused");
        
        Sleep(15);
        
    } while (key != 27);
    
    printf("\n");
    
    return 0;
}