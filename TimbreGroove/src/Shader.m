//
//  TGShader.m
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Shader.h"
#import "ShaderLocations.h"
#import "Texture.h"

static NSMutableDictionary * __shaders;

@implementation ShaderFactory

+(id)getShader:(NSString *)name klass:(Class)klass header:(NSString *)header;
{
    
    if (header == nil )
        header = @"";
    
    NSString * tag = header == @"" ? @"(default)" : header;

    NSString * key = [NSString stringWithFormat:@"%@-%@-%@", name, NSStringFromClass(klass), tag];
    if( !__shaders )
    {
        __shaders = [NSMutableDictionary new];
    }
    else
    {
        Shader * s = __shaders[key];
        if( s )
        {
#if DEBUG
            NSLog(@"returning shader of type: %@ (%d)", key, s.program);
#endif
            return s;
        }
    }
    
    id <ShaderInit> shader = [[klass alloc] initWithName: name andHeader:header];

#if DEBUG
    NSLog(@"created shader of type: %@ (%d)", key, ((Shader *)shader).program);
#endif
    
    __shaders[key] = shader;
    
    return shader;
    
}

@end


@interface Shader() {
    NSString * _header;
}
@end

@implementation Shader


-(id)init
{
    if( (self = [super init]))
    {
        _header = @"";
    }
    return self;
}

-(id)initWithName:(NSString *)name andHeader:(NSString *)header
{
    if( (self = [super init]))
    {
        _header = header;
        [self load:name withFragment:name];
    }
    return self;
}


#pragma mark - public

- (ShaderLocations *)getLocations
{
    if( !_locations )
        _locations = [[ShaderLocations alloc] initWithShader:self];
    return _locations;
}
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


#pragma mark - derived classes implement these

- (GLint)location:(SVariables)type
{
#if DEBUG
    NSLog(@"Don't know how to translate uniform name");
    exit(1);
#endif
    return SV_ERROR;
}


#pragma mark - internal stuff

- (BOOL)load:(NSString *)vname withFragment:(NSString *)fname
{
    GLuint vertShader, fragShader;
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
    
    _program = glCreateProgram();
    
    NSString * path = [[NSBundle mainBundle] pathForResource:vname ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:path]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    path = [[NSBundle mainBundle] pathForResource:fname ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:path]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    glAttachShader(_program, vertShader);
    glAttachShader(_program, fragShader);
    
    if (![self link:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
#if DEBUG
    NSLog(@"shader program: %d", _program);
#endif    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    
    NSString * src = [NSString stringWithContentsOfFile:file
                                                  encoding:NSUTF8StringEncoding
                                                     error:nil] ;
    if (!src) {
        NSLog(@"Failed to load vertex shader %@",file);
        return NO;
    }

    if( _header )
        src = [_header stringByAppendingString:src];
    
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
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    GLint status;
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
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
        return NO;
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

@end
