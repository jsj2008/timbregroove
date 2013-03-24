//
//  Global.m
//  TimbreGroove
//
//  Created by victor on 2/5/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#define NO_GLOBAL_DECLS
#import "Global.h"
#import "TGTypes.h"
#import <stdarg.h>

NSString const * kGlobalScene        = @"scene";
NSString const * kGlobalRecording    = @"recording";
NSString const * kGlobalDisplayGraph = @"displayGraph";

static Global * __sharedGlobal;

@implementation Global

-(id)init
{
    self = [super init];
    if( self )
    {
    }
    return self;
}

+(Global *)sharedInstance
{
    @synchronized(self) {
        if( !__sharedGlobal )
            __sharedGlobal = [Global new];
    }
    
    return __sharedGlobal;
}
@end

static LogLevel _currentLL = LLShitsOnFire;

void TGLog(LogLevel loglevel,NSString *format, ...)
{
    if( (loglevel == LLShitsOnFire) || ((loglevel & _currentLL) != 0)  )
    {
        va_list ap;
        va_start (ap, format);
#if 0
        char buf[1000];
        strcpy(buf,[format UTF8String]);
        strcat(buf, "\n");
        vprintf(buf, ap);
#else
        NSLogv(format,ap);
#endif
        va_end (ap);
    }
}
LogLevel TGSetLogLevel(LogLevel logLevel)
{
    LogLevel prev = _currentLL;
    _currentLL = logLevel;
    return prev;
}
