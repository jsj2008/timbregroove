//
//  TGShader.m
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Shader.h"
#import "ShaderLocations.h"
#import <libkern/OSAtomic.h>

#define ATOMIC_INC(c) OSAtomicCompareAndSwap32Barrier(c,c+1,(volatile int32_t *)&c);

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
        NSLog(@"Failed to compile vertex shader");
        exit(1);
    }
    
    GLuint fshader;
    path = [[NSBundle mainBundle] pathForResource:@(frag) ofType:@"fsh"];
    if (![self compileShader:&fshader type:GL_FRAGMENT_SHADER file:path headers:headers]) {
        NSLog(@"Failed to compile fragment shader");
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
        
        NSLog(@"Failed to link program: %d", _program);
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
#if DEBUG
    NSLog(@"created shader: %@ (%d)" ,self.description,_program);
#endif
    return YES;
    
}
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file headers:(NSString * )headers
{
    NSString * src = [NSString stringWithContentsOfFile:file
                                               encoding:NSUTF8StringEncoding
                                                  error:nil] ;
    if (!src) {
        NSLog(@"Failed to load vertex shader %@",file);
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
        NSLog(@"Shader %@ compile log:\n%s", file, log);
        free(log);
    }
#endif
    
    GLint status;
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        NSLog(@"Bad compile status: %d",status);
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
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        NSLog(@"Bad link status: %d",status);
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
        NSLog(@"Program validate log:\n%s", log);
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
        NSLog(@"Deleting program: %d",_program);
        glDeleteProgram(_program);
        _program = 0;
    }
}
@end

typedef struct _VarQueueItem
{
    int indexIntoName;
    TGUniformType type;
    union {
        float f;
        int i;
        CGPoint pt;
        GLKVector3 v3;
        GLKVector4 v4;
    };
} VarQueueItem;

typedef struct _VarQueueItem VarStoreItem;

@interface Shader () {
    const char ** _names;
    
    int           _numVars;
    int           _lastAttr;
    id            _poolKey;
    ShaderLocations * _locations;
    
    int _varQueueCount;
    int _varQueueMax;
    VarQueueItem * _varQueue;
    VarStoreItem * _currentValues;
    int _nextCurrentValue;
}

@end
@implementation Shader

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
    NSString * shaderId = [NSString stringWithFormat:@"%s-%s-%@-%@",vert,frag,tag,[EAGLContext currentContext]];
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
#ifdef DEBUG
    if( foundShader )
        NSLog(@"reusing shader %d - %@",foundShader.program,shaderId);
#endif
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
    _numVars = numNames;
    _vars = (GLint *)malloc(sizeof(GLint)*_numVars);
    
    for( int i = 0; i < _numVars; i++ )
        _vars[i] = -1;
    
    if( ![self loadAndCompile:vert andFragment:frag andHeaders:headers] )
        return nil;

    _locations = [[ShaderLocations alloc] initWithShader:self];
    [self getLocationsForNames];
    
    _varQueueMax = 50;
    _varQueueCount = 0;
    _varQueue = malloc(_varQueueMax * sizeof(VarQueueItem));
    
    _nextCurrentValue = 0;
    _currentValues = malloc(_varQueueMax * sizeof(VarStoreItem));
    
    NSString * tag = [headers length] ? headers : @"default";
    _poolKey = [NSString stringWithFormat:@"%s-%s-%@",vert,frag,tag];
    if( !__shaders )
        __shaders = [NSHashTable weakObjectsHashTable];
    [__shaders addObject:self];
    return self;
}

-(void)dealloc
{
    free(_vars);
    free(_varQueue);
    free(_currentValues);
    [__shaders removeObject:self];
}

#pragma mark - public

- (void)getLocationsForNames
{
    [self use];
    for( int i = 0; i < _numVars; i++ )
        [self location:i];
}

- (GLint)location:(int)indexIntoNames
{
    if( _vars[indexIntoNames] == -1 )
    {
        if( indexIntoNames > _lastAttr )
            _vars[indexIntoNames] = glGetUniformLocation(_program, _names[indexIntoNames]);
        else
            _vars[indexIntoNames] = glGetAttribLocation(_program, _names[indexIntoNames]);
#if DEBUG
        if( !_acceptMissingVars && _vars[indexIntoNames] == -1 )
        {
            NSLog(@"Can't find attr/uniform for (%d) %s in program %d", indexIntoNames, _names[indexIntoNames],_program);
            exit(1);
        }
#endif
    }
    
    return _vars[indexIntoNames];
}

- (void)writeToLocation:(int)indexIntoNames type:(TGUniformType)type data:(void*)data
{
    if( _acceptMissingVars && _vars[indexIntoNames] == -1 )
        return;
    [_locations writeToLocation:_vars[indexIntoNames] type:type data:data];
}

-(const char *)nameForIndex:(int)index
{
    return _names[index];
}

- (void) prepareRender:(TG3dObject *)object
{
    @synchronized(self) {
        VarQueueItem * vqi = _varQueue;
        for( int i = 0; i < _varQueueCount; i++, vqi++ )
        {
            [_locations writeToLocation:_vars[vqi->indexIntoName]
                                   type:vqi->type
                                   data:&vqi->f];
        }
        _varQueueCount = 0;
    }
}

-(void)floatParameter:(NSMutableDictionary *)putHere idx:(int)idx 
{
    putHere[ @(_names[idx]) ] = [Parameter withBlock:^(float f){
        _varQueue[_varQueueCount] = (VarQueueItem){ idx, TG_FLOAT, { .f = f }};
        ATOMIC_INC(_varQueueCount);
    }];
}

-(void)floatParameter:(NSMutableDictionary *)putHere idx:(int)idx value:(float)value range:(FloatRange)range
{
    putHere[ @(_names[idx]) ] = [FloatParameter withRange:range value:value block:^(float f){
        _varQueue[_varQueueCount] = (VarQueueItem){ idx, TG_FLOAT, { .f = f }};
        ATOMIC_INC(_varQueueCount);
    }];
}

-(void)pointParameter:(NSMutableDictionary *)putHere idx:(int)idx
{
    int myCurrentValueIndex = _nextCurrentValue;
    Parameter * parameter = [Parameter withBlock:[^(CGPoint pt) {
        _varQueue[_varQueueCount] = (VarQueueItem){ idx, TG_POINT, { .pt = pt } };
        _currentValues[myCurrentValueIndex].pt = pt;
        ATOMIC_INC(_varQueueCount);        
    } copy]];
    
    _currentValues[_nextCurrentValue].pt = (CGPoint){0,0};
    parameter.additive = false;
    [parameter setNativeValue:&_currentValues[_nextCurrentValue].pt ofType:TGC_POINT size:sizeof(CGPoint)];
    
    putHere[ @(_names[idx]) ] = parameter;
    
    ++_nextCurrentValue;
}

@end

