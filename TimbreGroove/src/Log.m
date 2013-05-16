//
//  Log.c
//  TimbreGroove
//
//  Created by victor on 3/25/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Log.h"

static const char * logStringToBit[] = {
    "LLShitsOnFire",
    "LLKindaImportant",
    "LLObjLifetime",
    "LLAudioTweaks",
    "LLJustSayin",
    "LLGLResource",
    "LLMidiStuff",
    "LLCaptureOps",
    "LLAudioResource",
    "LLShaderStuff",
    "LLGestureStuff",
    "LLMeshImporter",
    "LLLights"
};

static LogLevel _currentLL = LLShitsOnFire;

void TGLog_CLASSIC(LogLevel loglevel,NSString *format, ...)
{
    if( (loglevel == LLShitsOnFire) || ((loglevel & _currentLL) != 0)  )
    {
        va_list ap;
        va_start (ap, format);
        NSLogv(format,ap);
        va_end (ap);
    }
}

void TGLogc(LogLevel loglevel,const char * format, ...)
{
    if( (loglevel == LLShitsOnFire) || ((loglevel & _currentLL) != 0)  )
    {
        va_list ap;
        va_start (ap, format);
        NSLogv(@(format),ap);
        va_end (ap);
    }    
}

void TGLogp(LogLevel loglevel,NSString * format, ...)
{
    if( (loglevel == LLShitsOnFire) || ((loglevel & _currentLL) != 0)  )
    {
        va_list ap;
        va_start (ap, format);
        NSString * str = [[NSString alloc] initWithFormat:format arguments:ap];
        printf("%s\n",[str UTF8String]);
        va_end (ap);
    }
}

void TGLogpc(LogLevel loglevel,const char * format, ...)
{
    if( (loglevel == LLShitsOnFire) || ((loglevel & _currentLL) != 0)  )
    {
        va_list ap;
        va_start (ap, format);
        NSString * str = [[NSString alloc] initWithFormat:@(format) arguments:ap];
        printf("%s\n",[str UTF8String]);
        va_end (ap);
    }
}

LogLevel TGLogStringsToBits(NSDictionary *dict)
{
    __block LogLevel level = 0;
    [dict each:^(NSString * name, NSNumber * value) {
        if( [value boolValue] )
        {
            for( int i = 0; i < sizeof(logStringToBit)/sizeof(logStringToBit[0]); i++ )
            {
                if( [name isEqualToString:@(logStringToBit[i])] )
                {
                    level |= (1 << (i-1));
                    break;
                }
            }
        }
    }];
    return level;
}

LogLevel TGSetLogLevel(LogLevel logLevel)
{
    LogLevel prev = _currentLL;
    _currentLL = logLevel;
    return prev;
}

LogLevel TGGetLogLevel()
{
    return _currentLL;
}