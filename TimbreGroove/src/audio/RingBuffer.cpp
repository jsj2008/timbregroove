//
//  RingBuffer.cpp
//  TimbreGroove
//
//  Created by victor on 2/12/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#include "RingBuffer.h"
#include "CARingBuffer.h"


RingBufferOpaque RingBuffer(int nChannels, UInt32 bytesPerFrame, UInt32 capacityFrames)
{
    CARingBuffer * rb = new CARingBuffer;
    rb->Allocate(nChannels, bytesPerFrame, capacityFrames);
    return rb;
}

void RingBufferRelease(RingBufferOpaque rbo)
{
    delete static_cast<CARingBuffer *>(rbo);
}
void RingBufferDeallocate(RingBufferOpaque rbo)
{
    static_cast<CARingBuffer *>(rbo)->Deallocate();
}

int	RingBufferStore(RingBufferOpaque rbo, const AudioBufferList *abl, UInt32 nFrames, SInt64 frameNumber)
{
    return static_cast<CARingBuffer *>(rbo)->Store(abl, nFrames, frameNumber);
}

int RingBufferFetch(RingBufferOpaque rbo, AudioBufferList *abl, UInt32 nFrames, SInt64 frameNumber)
{
    return static_cast<CARingBuffer *>(rbo)->Fetch(abl, nFrames, frameNumber);
}

