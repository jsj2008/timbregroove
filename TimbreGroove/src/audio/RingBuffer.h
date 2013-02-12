//
//  RingBuffer.h
//  TimbreGroove
//
//  Created by victor on 2/12/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#ifndef __TimbreGroove__RingBuffer__
#define __TimbreGroove__RingBuffer__

#include <CoreAudio/CoreAudioTypes.h>

#ifdef __cplusplus
extern "C"
{
#endif

typedef void * RingBufferOpaque;

RingBufferOpaque RingBuffer(int nChannels, UInt32 bytesPerFrame, UInt32 capacityFrames);
void RingBufferRelease(RingBufferOpaque rbo);
void RingBufferDeallocate(RingBufferOpaque rbo);

int	RingBufferStore(RingBufferOpaque rbo, const AudioBufferList *abl, UInt32 nFrames, SInt64 timeStamp);
int RingBufferFetch(RingBufferOpaque rbo, AudioBufferList *abl, UInt32 nFrames, SInt64 timeStamp);
    
#ifdef __cplusplus
}
#endif

#endif /* defined(__TimbreGroove__RingBuffer__) */
