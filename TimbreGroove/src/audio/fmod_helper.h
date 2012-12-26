//
//  fmod_helper.h
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#ifndef TimbreGroove_fmod_helper_h
#define TimbreGroove_fmod_helper_h


#import "fmod.h"
//#import "fmod.hpp"
#import "fmod_errors.h"

#define F_ERRCHECK(r) \
if ((r != FMOD_OK) && (r != FMOD_ERR_INVALID_HANDLE) && (r != FMOD_ERR_CHANNEL_STOLEN)) \
{ \
ERRCHECK(result); \
}

static inline void ERRCHECK(FMOD_RESULT result)
{
    if (result != FMOD_OK)
    {
        NSLog /*fprintf(stderr,*/( @"FMOD error! (%d) %s\n", result, FMOD_ErrorString(result));
        exit(-1);
    }
}


#endif
