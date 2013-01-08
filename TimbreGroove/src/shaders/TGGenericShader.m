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
    GLint     _vars[NUM_SVARIABLES];
    NSArray * _svTypes;
}
@end

@implementation TGGenericShader

-(id)init
{
    return [self initWithSVaribles:@[@(sv_pos)]];
}

-(id)initWithSVaribles:(NSArray *)svTypes
{
    if( (self = [super init]) )
    {
        _svTypes = [svTypes copy];
        [self __initStatics];
        [self load:SHADER_FILE withFragment:SHADER_FILE];
        [self use];
  //    self.useLighting = false;
    }
    
    return self;
}

- (void)__initStatics
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
        __names[sv_useLighting]= "u_useLighting";
        
        __namesInit = true;
    }
    
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

-(void)setPvm:(GLKMatrix4)pvm
{
    [self.locations writeToLocation:[self location:sv_pvm] type:TG_MATRIX4 data:pvm.m];
    _pvm = pvm;
}

-(void)setColor:(GLKVector4)color
{
    [self.locations writeToLocation:[self location:sv_ucolor] type:TG_VECTOR4 data:color.v];
    _color = color;
}

-(void)setOpacity:(float)opacity
{
    [self.locations writeToLocation:[self location:sv_opacity] type:TG_FLOAT data:&opacity];
    _opacity = opacity;
}

-(void)setUseLighting:(bool)useLighting
{
    [self.locations writeToLocation:[self location:sv_useLighting] type:TG_BOOL data:&useLighting];
    _useLighting = useLighting;
}

- (NSString *)processShaderSrc:(NSString *)src type:(GLenum)type
{
    NSString * pre = @"";
    
    for( NSNumber * num in _svTypes )
    {
        SVariables svar = [num intValue];
        NSString * ns;
        switch (svar) {
            case sv_acolor:
                ns = @"#define COLOR\n";
                break;
            case sv_normal:
                ns = @"#define NORMAL\n";
                break;
            case sv_uv:
                ns = @"#define TEXTURE\n";
                break;
            default:
                break;
        }
        if(ns)
            pre = [pre stringByAppendingString:ns];
    }
    
    return [pre stringByAppendingString:src];
}

@end
