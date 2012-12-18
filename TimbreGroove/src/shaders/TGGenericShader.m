//
//  TGGenericShader.m
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGGenericShader.h"

#define SHADER_FILE @"generic"

static bool         __namesInit = false;
static const char * __names[NUM_SVARIABLES];

@interface TGGenericShader() {
    GLint                   _vars[NUM_SVARIABLES];
    TGGenericElementParams  _initParams;
}
@end

@implementation TGGenericShader

-(TGGenericShader *)initWithParams:(TGGenericElementParams *)params
{
    if( (self = [super init]) )
    {
        for( int i = 0; i < sizeof(_vars)/sizeof(_vars[0]); i++ )
        {
            _vars[i] = SV_NONE;
        }
        
        if( !__namesInit )
        {
            __names[sv_acolor]  = "a_color";
            __names[sv_normal]  = "a_normal";
            __names[sv_pos]     = "a_position";
            __names[sv_uv]      = "a_uv";
            
            __names[sv_opacity] = "u_opacity";
            __names[sv_pvm]     = "u_pvm";
            __names[sv_sampler] = "u_sampler";
            __names[sv_ucolor]  = "u_color";
            
            __namesInit = true;
        }
        
        _initParams = *params;
        _color      = _initParams.color;
        _opacity    = _initParams.opacity;
        
        [self load:SHADER_FILE withFragment:SHADER_FILE];
        
    }
    
    return self;
}

- (GLint)location:(SVariables)type
{
    if( _vars[type] == SV_NONE )
    {
        if( type > SV_LAST_ATTR )
            _vars[type] = glGetUniformLocation( _program, __names[type]);
        else
            _vars[type] = glGetAttribLocation(_program, __names[type]);
#if DEBUG
        if( _vars[type] == SV_ERROR )
        {
            NSLog(@"Can't find attr/uniform for (%d) %s", (int)type, __names[type]);
            exit(1);
        }
#endif
    }
    
    return _vars[type];    
}

-(void)writeUniforms:(float *)matrix
{
    glUniformMatrix4fv( [self location:sv_pvm], 1, 0, matrix );
    
    if( _color.v[0] != -1 )
        glUniform4fv([self location:sv_ucolor], 1, _color.v);

    if( _opacity != 1.0f )
        glUniform1f([self location:sv_opacity], _opacity);
}

- (NSString *)processShaderSrc:(NSString *)src type:(GLenum)type
{
    NSString * pre = @"";
    
    for( int i = 0; i < _initParams.numStrides; i++ )
    {
        TGVertexStride * stride = _initParams.strides + i;
        if( stride->tgVarType == sv_acolor )
            pre = [pre stringByAppendingString:@"#define COLOR\n"];
        else if( stride->tgVarType == sv_normal )
            pre = [pre stringByAppendingString:@"#define NORMAL\n"];
        else if( stride->tgVarType == sv_uv )
            pre = [pre stringByAppendingString:@"#define TEXTURE\n"];
    }
    
    if( type == GL_FRAGMENT_SHADER )
    {
        if( _color.v[0] != -1 )
            pre = [pre stringByAppendingString:@"#define UCOLOR\n"];
        
        if( _opacity != 1.0 )
            pre = [pre stringByAppendingString:@"#define OPACITY\n"];
    }
    
    return [pre stringByAppendingString:src];

}

@end
