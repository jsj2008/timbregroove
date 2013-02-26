//
//  TGShader.m
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Shader.h"
#import "ShaderLocations.h"

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


@interface Shader () {
    const char ** _names;
    
    int           _numVars;
    int           _lastAttr;
    id            _poolKey;
    ShaderLocations * _locations;
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
    
}
@end


@implementation ShaderParameter

-(id)initWithShaderDef:(ShaderParameterDefinition *)sdef
{
    return [super initWithDef:(ParameterDefintion *)sdef valueNotify:nil];
}

-(void)setShader:(Shader *)shader
{
    // These are set of relatively unrelated tasks
    // but they might as well be done here:
    
    // 1. set this instance's shader
    //
    _shader = shader;
    
    // 2. expose the shader variable name for setting up trigger maps
    //
    ShaderParameterDefinition * spd = (ShaderParameterDefinition *)_pd;
    self.parameterName = @([shader nameForIndex:spd->indexIntoNames]);
    
    // 3. set up the trigger ParamBlock
    //
    self.valueNotify = ^{
        [shader writeToLocation:spd->indexIntoNames type:spd->pd.type data:&spd->pd.currentValue];
    };
    
    // 4. set the default value into the shader
    //
    [shader writeToLocation:spd->indexIntoNames type:spd->pd.type data:&spd->pd.def];
}

@end

