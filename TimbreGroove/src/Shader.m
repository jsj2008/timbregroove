//
//  TGShader.m
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Shader.h"
#import <libkern/OSAtomic.h>

#define ATOMIC_INC(c) OSAtomicCompareAndSwap32Barrier(c,c+1,(volatile int32_t *)&c);
#define EMPTY_RANGE (FloatRange){0,0}

static NSHashTable * __shaders;

@implementation ShaderWrapper

- (void)use
{
#ifdef CACHE_PROGRAM
    // TODO: does this work?
    static GLuint __lastProg = (GLuint)-1;
    if( _program != __lastProg )
    {
        glUseProgram(_program);
        __lastProg = _program;
    }
#else
    glUseProgram(_program);
#endif
}

- (BOOL)loadAndCompile:(const char*)vert andFragment:(const char*)frag andHeaders:(NSString *)headers
{
    _program = glCreateProgram();
    
    GLuint vshader;
    NSString * path = [[NSBundle mainBundle] pathForResource:@(vert) ofType:@"vsh"];
    if (![self compileShader:&vshader type:GL_VERTEX_SHADER file:path headers:headers]) {
        TGLog(LLShitsOnFire, @"Failed to compile vertex shader");
        exit(1);
    }
    
    GLuint fshader;
    path = [[NSBundle mainBundle] pathForResource:@(frag) ofType:@"fsh"];
    if (![self compileShader:&fshader type:GL_FRAGMENT_SHADER file:path headers:headers]) {
        TGLog(LLShitsOnFire, @"Failed to compile fragment shader");
        exit(1);
    }
    
    glAttachShader(_program, vshader);
    glAttachShader(_program, fshader);
    
    if (![self link:_program])
    {
        if (vshader) {
            glDeleteShader(vshader);
        }
        if (fshader) {
            glDeleteShader(fshader);
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        TGLog(LLShitsOnFire, @"Failed to link program: %d", _program);
        exit(1);
    }
    
    // Release vertex and fragment shaders.
    if (vshader) {
        glDetachShader(_program, vshader);
        glDeleteShader(vshader);
    }
    if (fshader) {
        glDetachShader(_program, fshader);
        glDeleteShader(fshader);
    }
    return YES;
    
}
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file headers:(NSString * )headers
{
    NSString * src = [NSString stringWithContentsOfFile:file
                                               encoding:NSUTF8StringEncoding
                                                  error:nil] ;
    if (!src) {
        TGLog(LLShitsOnFire, @"Failed to load vertex shader %@",file);
        exit(1);
    }
    
    if( [headers length])
        src = [headers stringByAppendingString:src];
    
    const GLchar *source = [src UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        TGLog(LLShitsOnFire, @"Shader %@ compile log:\n%s", file, log);
        free(log);
    }
#endif
    
    GLint status;
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        TGLog(LLShitsOnFire, @"Bad compile status: %d",status);
        exit(1);
    }
    
    return YES;
}

- (BOOL)link:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        TGLog(LLShitsOnFire, @"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        TGLog(LLShitsOnFire, @"Bad link status: %d",status);
        exit(1);
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        TGLog(LLShitsOnFire, @"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

-(void)dealloc
{
    /*
     If a program object to be deleted has shader objects attached to it, those shader
     objects will be automatically detached but not deleted unless they have already
     been flagged for deletion by a previous call to glDeleteShader.
     */
    
    if( _program )
    {
        TGLog(LLGLResource, @"Deleting program: %d",_program);
        glDeleteProgram(_program);
        _program = 0;
    }
}
@end


#pragma mark Types for Shader

typedef struct _ValueQueueItem
{
    int indexIntoName;
    TGUniformType type;
    union {
        float f;
        int i;
        CGPoint pt;
        GLKVector3 gv3;
        GLKVector4 gv4;
        TGVector3 v3;
        
    };
} ValueQueueItem;

typedef struct _ValueQueueItem ValueCacheItem;

typedef enum _sfpType {
    sfpt_straightUp,
    sfpt_scaling,
    sfpt_neg11,
    sfpt_01
} sfpType;

@implementation Shader {
    const char ** _names;
    
    int           _numLocations;
    int           _lastAttr;
    id            _poolKey;
    
    // Values that have been set by other parts
    // of the app wait in the queue for the
    // display thread to pick them up and write
    // to the shader before render:w:h:
    // The lifetime of these values is exactly
    // one update:/render: cycle
    int _valueQueueIndex;
    int _valueQueueMax;
    ValueQueueItem * _valueQueue;
    
    // Still a work in progress:
    // Values that have been set by other parts
    // of the app will be stored here so that
    // tweeners can query them. This is only
    // needed for Parameter objects that do have
    // storage for their values.
    int _valueCacheIndex;
    int _valueCacheMax;
    ValueCacheItem * _valueCache;
    
    FloatParamBlock _fparam;
}


+(id)shaderWithVertex:(const char *)vert
          andFragment:(const char *)frag
          andVarNames:(const char **)names
          andNumNames:(int)numNames
          andLastAttr:(int)lastAttr
           andHeaders:(NSString *)headers
{
    Shader * shader = [Shader shaderFromPoolWithVertex:vert
                                           andFragment:frag
                                           andVarNames:names
                                           andNumNames:numNames
                                           andLastAttr:lastAttr
                                            andHeaders:headers];
    if( !shader )
    {
        shader = [[Shader alloc] initWithVertex:vert
                                    andFragment:frag
                                    andVarNames:names
                                    andNumNames:numNames
                                    andLastAttr:lastAttr
                                     andHeaders:headers];
    }
    return shader;
}

+(id)shaderFromPoolWithVertex:(const char *)vert
                  andFragment:(const char *)frag
                  andVarNames:(const char **)names
                  andNumNames:(int)numNames
                  andLastAttr:(int)lastAttr
                   andHeaders:(NSString *)headers
{
    NSString * tag = [headers length] ? headers : @"default";
    NSString * shaderId = [NSString stringWithFormat:@"%s-%s-%@\n%@",vert,frag,[EAGLContext currentContext],tag];
    Shader * foundShader = nil;
    if( __shaders )
    {
        for( Shader * testShader in __shaders )
        {
            if( [testShader->_poolKey isEqualToString:shaderId] )
            {
                foundShader = testShader;
                break;
            }
        }
    }
    if( foundShader )
    {
        TGLog(LLGLResource | LLShaderStuff, @"reusing shader %d - %@",foundShader.program,shaderId);
    }
    return foundShader;
}

-(id)initWithVertex:(const char *)vert
        andFragment:(const char *)frag
        andVarNames:(const char **)names
        andNumNames:(int)numNames
        andLastAttr:(int)lastAttr
         andHeaders:(NSString *)headers
{
    if( !(self = [super init]) )
        return nil;

    _names = names;
    _lastAttr = lastAttr;
    _numLocations = numNames;
    _locations = (GLint *)malloc(sizeof(GLint)*_numLocations);
    
    for( int i = 0; i < _numLocations; i++ )
        _locations[i] = -1;
    
    if( ![self loadAndCompile:vert andFragment:frag andHeaders:headers] )
        return nil;

    [self getLocationsForNames];
    
    _valueQueueMax = 50;
    _valueQueueIndex = 0;
    _valueQueue = malloc(_valueQueueMax * sizeof(ValueQueueItem));
    
    _valueCacheMax = _valueQueueMax;
    _valueCacheIndex = 0;
    _valueCache = malloc(_valueCacheMax * sizeof(ValueCacheItem));
    
    NSString * tag = [headers length] ? headers : @"default";
    _poolKey = [NSString stringWithFormat:@"%s-%s-%@\n%@",vert,frag,[EAGLContext currentContext],tag];

    if( !__shaders )
        __shaders = [NSHashTable weakObjectsHashTable];
    [__shaders addObject:self];
    TGLog(LLGLResource | LLShaderStuff, @"created shader: %@ (%d) %@" ,self,_program, _poolKey);
    
    return self;
}

-(void)dealloc
{
    free(_locations);
    free(_valueQueue);
    free(_valueCache);
    [__shaders removeObject:self];
}

#pragma mark - public

- (void)getLocationsForNames
{
    [self use];
    for( int i = 0; i < _numLocations; i++ )
        [self location:i];
}

- (GLint)location:(int)indexIntoNames
{
    if( _locations[indexIntoNames] == -1 )
    {
        if( indexIntoNames > _lastAttr )
            _locations[indexIntoNames] = glGetUniformLocation(_program, _names[indexIntoNames]);
        else
            _locations[indexIntoNames] = glGetAttribLocation(_program, _names[indexIntoNames]);
#if DEBUG
        
        if( _locations[indexIntoNames] == -1 )
        {
            LogLevel logl = _acceptMissingVars ? LLShaderStuff : LLShitsOnFire;
            TGLog(logl, @"Can't find attr/uniform for (%d) %s in program %d %s",
                  indexIntoNames,
                  _names[indexIntoNames],
                  _program,
                  _acceptMissingVars ? "(eh, probablly fine)" : "(wups)");
            if( !_acceptMissingVars )
                exit(-1);
        }
        
#endif
    }
    
    return _locations[indexIntoNames];
}

- (void)writeFloats:(int)indexIntoNames numFloats:(int)numFloats data:(void*)data
{
    glUniform1fv( _locations[indexIntoNames], numFloats, data);
}

- (void)writeToLocationTranspose:(int)indexIntoNames type:(TGUniformType)type data:(void*)data count:(unsigned int)count
{
    GLint location = _locations[indexIntoNames];
    
    switch(type)
    {            
        case TG_MATRIX3:
            glUniformMatrix3fv(location, count, GL_TRUE, data);
            break;
            
        case TG_MATRIX4:
            glUniformMatrix4fv(location, count, GL_TRUE, data);
            break;
        default:
            break;
    }
}

- (void)writeToLocation:(int)indexIntoNames type:(TGUniformType)type data:(void*)data
{
    [self writeToLocation:indexIntoNames type:type data:data count:1];
}

- (void)writeToLocation:(int)indexIntoNames type:(TGUniformType)type data:(void*)data count:(unsigned int)count
{
    if(  _locations[indexIntoNames] == -1 )
    {
        TGLog(LLShaderStuff, @"Trying to write to %s (%d) but doesn't exist",_names[indexIntoNames],indexIntoNames);
        return;
    }
    
    GLint location = _locations[indexIntoNames];
    
    switch(type)
    {
        case TG_FLOAT:
        case TG_BOOL_FLOAT:
            glUniform1fv(location, count, data);
            break;
            
        case TG_VECTOR2:
            glUniform2fv(location, count, data);
            break;
            
        case TG_VECTOR3:
            glUniform3fv(location, count, data);
            break;
            
        case TG_VECTOR4:
            glUniform4fv(location, count, data);
            break;
            
        case TG_MATRIX3:
            glUniformMatrix3fv(location, count, GL_FALSE, data);
            break;
            
        case TG_MATRIX4:
            glUniformMatrix4fv(location, count, GL_FALSE, data);
            break;
            
        case TG_INT:
        case TG_TEXTURE:
        case TG_BOOL:
            glUniform1iv(location, count, data);
            break;
    }
}

-(const char *)nameForIndex:(int)indexIntoNames
{
    return _names[indexIntoNames];
}

- (void) prepareRender:(Node3d *)object
{
    @synchronized(self) {
        ValueQueueItem * vqi = _valueQueue;
        for( int i = 0; i < _valueQueueIndex; i++, vqi++ )
        {
            TGLog(LLShaderStuff, @"Writing: %s (%d) loc:%d type:%d (%f, %f, %f)",_names[vqi->indexIntoName], vqi->indexIntoName,
                  _locations[vqi->indexIntoName],
                  vqi->type, vqi->gv3.x, vqi->gv3.y, vqi->gv3.z);
            
            [self writeToLocation:vqi->indexIntoName
                             type:vqi->type
                             data:&vqi->f];
        }
        _valueQueueIndex = 0;
    }
}

-(Parameter *)floatParam:(NSMutableDictionary *)putHere
          indexIntoNames:(int)idx
                   value:(float)value
                   range:(FloatRange)range
               forObject:(id)target
                    type:(sfpType)type
{
    FloatParamBlock fpb = [^(float f)
    {
        _valueQueue[_valueQueueIndex] = (ValueQueueItem){ idx, TG_FLOAT, { .f = f }};
        ATOMIC_INC(_valueQueueIndex);
    } copy];
    
    Parameter * parameter;
    
    switch (type) {
        case sfpt_straightUp:
            parameter = [Parameter withBlock:fpb];
            break;
            
        case sfpt_scaling:
            parameter = [FloatParameter withScaling:range value:value block:fpb];
            break;
            
        case sfpt_neg11:
            parameter = [FloatParameter withNeg11Scaling:range value:value block:fpb];
            break;
            
        case sfpt_01:
            parameter = [FloatParameter with01Value:value block:fpb];
            break;
    }
    
    parameter.targetObject = target;
    putHere[ @(_names[idx]) ] = parameter;
    return parameter;
}

-(Parameter *)floatParameter:(NSMutableDictionary *)putHere
       indexIntoNames:(int)idx
{
    return [self floatParam:putHere indexIntoNames:idx value:0 range:EMPTY_RANGE forObject:nil type:sfpt_straightUp];
}

-(Parameter *)floatParameter:(NSMutableDictionary *)putHere
       indexIntoNames:(int)idx
            forObject:(Node3d *)target
{
    return [self floatParam:putHere indexIntoNames:idx value:0 range:EMPTY_RANGE forObject:target type:sfpt_straightUp];
}

-(Parameter *)floatParameter:(NSMutableDictionary *)putHere
       indexIntoNames:(int)idx
                value:(float)value
                range:(FloatRange)range
{
    return [self floatParam:putHere indexIntoNames:idx value:value range:range forObject:nil type:sfpt_scaling];
}

-(Parameter *)floatParameter:(NSMutableDictionary *)putHere
       indexIntoNames:(int)idx
                value:(float)value
                range:(FloatRange)range
            forObject:(Node3d *)target
{
    return [self floatParam:putHere indexIntoNames:idx value:value range:range forObject:target type:sfpt_scaling];
}

-(Parameter *)floatParameter:(NSMutableDictionary *)putHere
              indexIntoNames:(int)idx
                       value:(float)value
                  neg11range:(FloatRange)range
{
    return [self floatParam:putHere indexIntoNames:idx value:value range:range forObject:nil type:sfpt_neg11];
}

-(Parameter *)floatParameter:(NSMutableDictionary *)putHere
              indexIntoNames:(int)idx
                       value:(float)value
                  neg11range:(FloatRange)range
                   forObject:(Node3d *)target
{
    return [self floatParam:putHere indexIntoNames:idx value:value range:range forObject:target type:sfpt_neg11];
}

-(Parameter *)vecParameter:(NSMutableDictionary *)putHere
            indexIntoNames:(int)idx
                 forObject:(Node3d *)target
                      type:(char)type
{
    id block = nil;
    size_t sz = 0;
    int myCurrentValueIndex = _valueCacheIndex;
    
    if( type == TGC_POINT )
    {
        block = [^(CGPoint pt)
                 {
                     _valueQueue[_valueQueueIndex] = (ValueQueueItem){ idx, TG_POINT, { .pt = pt } };
                     _valueCache[myCurrentValueIndex].pt = pt;
                     ATOMIC_INC(_valueQueueIndex);
                 } copy];
        
        sz = sizeof(CGPoint);
    }
    else if( type == TGC_VECTOR3 )
    {
        block = [^(TGVector3 vec3)
                 {
                     _valueQueue[_valueQueueIndex] = (ValueQueueItem){ idx, TG_VECTOR3, { .v3 = vec3 } };
                     _valueCache[myCurrentValueIndex].v3 = vec3;
                     ATOMIC_INC(_valueQueueIndex);
                 } copy];
        
        sz = sizeof(GLKVector3);
    }
    
    Parameter * parameter = [Parameter withBlock:block];
    _valueCache[_valueCacheIndex].gv3 = (GLKVector3){0,0,0};
    parameter.additive = false;
    [parameter setNativeValue:&_valueCache[_valueCacheIndex].pt ofType:type size:sz];
    parameter.targetObject = target;
    putHere[ @(_names[idx]) ] = parameter;
    ++_valueCacheIndex;
    return parameter;
    
}

-(Parameter *)pointParameter:(NSMutableDictionary *)putHere
              indexIntoNames:(int)idx
{
    return [self vecParameter:putHere indexIntoNames:idx forObject:nil type:TGC_POINT];
}


-(Parameter *)pointParameter:(NSMutableDictionary *)putHere
       indexIntoNames:(int)idx
            forObject:(Node3d *)target
{
    
    return [self vecParameter:putHere indexIntoNames:idx forObject:target type:TGC_POINT];
}

-(Parameter *)vec3Parameter :(NSMutableDictionary *)putHere
       indexIntoNames:(int)idx
{
    return [self vecParameter:putHere indexIntoNames:idx forObject:nil type:TGC_VECTOR3];
}

-(Parameter *)vec3Parameter :(NSMutableDictionary *)putHere
       indexIntoNames:(int)idx
            forObject:(Node3d *)target
{
    return [self vecParameter:putHere indexIntoNames:idx forObject:target type:TGC_VECTOR3];
}

@end

