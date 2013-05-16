//
//  Log.h
//  TimbreGroove
//
//  Created by victor on 3/25/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#ifndef TimbreGroove_Log_h
#define TimbreGroove_Log_h

#ifndef __OBJC__
extern "C" {
#endif
    
    typedef enum LogLevel {
        LLShitsOnFire = 0,
        LLKindaImportant = 1,
        LLObjLifetime = 1 << 1,
        LLAudioTweaks = 1 << 2,
        LLJustSayin = 1 << 3,
        LLGLResource = 1 << 4,
        LLMidiStuff = 1 << 5,
        LLCaptureOps = 1 << 6,
        LLAudioResource = 1 << 7,
        LLShaderStuff = 1 << 8,
        LLGestureStuff = 1 << 9,
        LLMeshImporter = 1 << 10,
        LLLights = 1 << 11,
    } LogLevel;
    
    LogLevel TGSetLogLevel(LogLevel);
    LogLevel TGGetLogLevel();
#ifdef __OBJC__
    void TGLog_CLASSIC(LogLevel,NSString *format, ...);
    void TGLogp(LogLevel,NSString * format, ...); // use printf
#define TGLog TGLogp
    
    LogLevel TGLogStringsToBits(NSDictionary *);
    
#else
    void TGLogc(LogLevel,const char * format, ...);
    void TGLogpc(LogLevel,const char * format, ...); // use printf
}
#endif

#endif
