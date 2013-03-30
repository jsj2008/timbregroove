//
//  Log.c
//  TimbreGroove
//
//  Created by victor on 3/25/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Log.h"

static LogLevel _currentLL = LLShitsOnFire;

void TGLog(LogLevel loglevel,NSString *format, ...)
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

LogLevel TGSetLogLevel(LogLevel logLevel)
{
    LogLevel prev = _currentLL;
    _currentLL = logLevel;
    return prev;
}
