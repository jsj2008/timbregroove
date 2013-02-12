//
//  Mixer+Diag.m
//  TimbreGroove
//
//  Created by victor on 2/9/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Mixer+Diag.h"
#import <AudioUnit/AudioUnit.h>


@implementation Mixer (Diag)

-(void)dumpParameters:(AudioUnit)inUnit
{
    AudioUnitPropertyID     inID = kAudioUnitProperty_ParameterList;
    AudioUnitScope          inScope = kAudioUnitScope_Global;
    AudioUnitElement        inElement = 0;
    UInt32                  outDataSize;
    Boolean 				outWritable;
    
	OSStatus result = AudioUnitGetPropertyInfo(inUnit, inID, inScope, inElement, &outDataSize, &outWritable);
    
    CheckError(result, "Error getting parameters");
    
    NSLog(@"\nparaminfo size: %d \nWritable: %d", (unsigned int)outDataSize, (int)outWritable);
	int nparams = outDataSize / sizeof(AudioUnitPropertyID);
    AudioUnitParameterID auIDs[nparams];
	memset (auIDs, 0xFF, outDataSize);

	result = AudioUnitGetProperty(inUnit, inID, inScope, inElement, auIDs, &outDataSize);
    CheckError(result, "Error getting parameters (2)");
    
    char str[1000];
    
    for( int i = 0; i < nparams; i++ )
    {
        AudioUnitParameterInfo auinfo;
        UInt32 propertySize = sizeof(AudioUnitParameterInfo);
        result = AudioUnitGetProperty(inUnit,
                                            kAudioUnitProperty_ParameterInfo,
                                            inScope,
                                            auIDs[i],
                                            &auinfo,
                                            &propertySize);
        CheckError(result, "Error getting parameters (3)");
        
        if( auinfo.cfNameString )       
        {
            CFStringGetCString(auinfo.cfNameString, str, 1000, kCFStringEncodingUTF8);
        }
        else
            *str = 0;
        
        NSLog(@"parameter: %lu - %04lX %s / %s", auIDs[i], auIDs[i], (char *)auinfo.name, str);
        
        if (auinfo.flags & kAudioUnitParameterFlag_CFNameRelease) {
            if (auinfo.flags & kAudioUnitParameterFlag_HasCFNameString && auinfo.cfNameString != NULL)
                CFRelease(auinfo.cfNameString);
            if (auinfo.unit == kAudioUnitParameterUnit_CustomUnit && auinfo.unitName != NULL)
                CFRelease(auinfo.unitName);
        }
    }
    
}
@end
