//
//  Mixer+Diag.m
//  TimbreGroove
//
//  Created by victor on 2/9/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "SoundSystem+Diag.h"
#import <AudioUnit/AudioUnit.h>

typedef struct  tagAUFlagDump {
    const char * name;
    int e;
} AUFlagDump;

@implementation SoundSystem (Diag)

-(void)dumpParameters:(AudioUnit)inUnit forUnit:(NSString *)name
{
    AudioUnitPropertyID     inID = kAudioUnitProperty_ParameterList;
    AudioUnitScope          inScope = kAudioUnitScope_Global;
    AudioUnitElement        inElement = 0;
    UInt32                  outDataSize;
    Boolean 				outWritable;
    
	OSStatus result = AudioUnitGetPropertyInfo(inUnit, inID, inScope, inElement, &outDataSize, &outWritable);
    
    CheckError(result, "Error getting parameters");
    
    TGLog(LLShitsOnFire, @"\n ***** UNIT: %@ ******\nParaminfo size: %d Writable: %d", name, (unsigned int)outDataSize, (int)outWritable);
    if( outDataSize )
    {
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
            
            TGLog(LLShitsOnFire, @"parameter: %lu - %04lX %s / %s", auIDs[i], auIDs[i], (char *)auinfo.name, str);
            
            if (auinfo.flags & kAudioUnitParameterFlag_CFNameRelease) {
                if (auinfo.flags & kAudioUnitParameterFlag_HasCFNameString && auinfo.cfNameString != NULL)
                    CFRelease(auinfo.cfNameString);
                if (auinfo.unit == kAudioUnitParameterUnit_CustomUnit && auinfo.unitName != NULL)
                    CFRelease(auinfo.unitName);
            }
        }
    }
    
    AudioStreamBasicDescription asbd = {};
    unsigned long sizeASBD = sizeof(asbd);
    result = AudioUnitGetProperty(inUnit, kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output, 0, &asbd, &sizeASBD);
    
    TGLog(LLShitsOnFire, @"Output format (bus: 0):-----------------");
    [self printASBD:asbd];

    result = AudioUnitGetProperty(inUnit, kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input, 0, &asbd, &sizeASBD);
    
    TGLog(LLShitsOnFire, @"Input format:-----------------");
    [self printASBD:asbd];

}

- (void) printASBD: (AudioStreamBasicDescription) asbd
{
    char formatIDString[5];
    UInt32 formatID = CFSwapInt32HostToBig (asbd.mFormatID);
    bcopy (&formatID, formatIDString, 4);
    formatIDString[4] = '\0';
    
    AUFlagDump flags [] = {
        { " Float",  kAudioFormatFlagIsFloat },
        { " BigEndian",  kAudioFormatFlagIsBigEndian },
        { " SignedInt",  kAudioFormatFlagIsSignedInteger },
        { " Packed",  kAudioFormatFlagIsPacked },
        { " AlignedHigh",  kAudioFormatFlagIsAlignedHigh  },
        { " NonInterleaved",  kAudioFormatFlagIsNonInterleaved  },
        { " NonMixable",  kAudioFormatFlagIsNonMixable  },
        { " AllClear",  kAudioFormatFlagsAreAllClear  },
    };
    
    NSString * flagstr = @"";
    
    for (int i = 0; i < (sizeof(flags)/sizeof(flags[0])); i++) {
        if( (asbd.mFormatFlags & flags[i].e) != 0 )
        {
            flagstr = [flagstr stringByAppendingString:@(flags[i].name)];
        }
    }
    TGLog(LLShitsOnFire, @"  Sample Rate:         %10.0f",  asbd.mSampleRate);
    TGLog(LLShitsOnFire, @"  Format ID:           %10s",    formatIDString);
    TGLog(LLShitsOnFire, @"  Format Flags: %@ (%X)",  flagstr,  (unsigned int)asbd.mFormatFlags);
    TGLog(LLShitsOnFire, @"  Bytes per Packet:    %10d",    (unsigned int)asbd.mBytesPerPacket);
    TGLog(LLShitsOnFire, @"  Frames per Packet:   %10d",    (unsigned int)asbd.mFramesPerPacket);
    TGLog(LLShitsOnFire, @"  Bytes per Frame:     %10d",    (unsigned int)asbd.mBytesPerFrame);
    TGLog(LLShitsOnFire, @"  Channels per Frame:  %10d",    (unsigned int)asbd.mChannelsPerFrame);
    TGLog(LLShitsOnFire, @"  Bits per Channel:    %10d\n----------------------------\n",    (unsigned int)asbd.mBitsPerChannel);
}


-(void)dumpGraph:(AUGraph)processingGraph
{
    TGLog(LLShitsOnFire, @"Audio graph update >>>>>>>>>>>>>>>");
    CAShow(processingGraph);
}

@end
