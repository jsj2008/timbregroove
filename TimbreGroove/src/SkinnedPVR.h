//
//  SkinnedPVR.h
//  TimbreGroove
//
//  Created by victor on 1/15/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#ifndef __TimbreGroove__SkinnedPVR__
#define __TimbreGroove__SkinnedPVR__

#include <iostream>

typedef void * PVR_SKINNER;

PVR_SKINNER Skinner_Get(char *psSceneFile, char **ppTextureFiles, char **ppTextureName, int numTextures );
void        Skinner_Render(PVR_SKINNER skinner, float * modelMatrix);
void        Skinner_Destroy(PVR_SKINNER skinner);
void        Skinner_Pause(PVR_SKINNER skinner);
void        Skinner_Resume(PVR_SKINNER skinner);

enum EnvTypeStuff
{
	prefReadPath,
	prefWidth,
	prefHeight,		
    prefIsRotated,
    prefFullScreen
};

void          EnvExitMsg( const char * msg );
int           EnvGeti(int pref);
void *        EnvGet(int param);
int           EnvSet(int param,void *);
unsigned long EnvGetTime();

#endif /* defined(__TimbreGroove__SkinnedPVR__) */
