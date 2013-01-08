//
//  TGGenericShader.m
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "GenericShader.h"

#define SHADER_FILE @"generic"

static const char * __names[NUM_SVARIABLES] = {
    "a_color",
    "a_normal",
    "a_position",
    "a_uv",
    
    "u_pvm",
    "u_sampler",
    "u_color",
    
    "u_normalMat",
    "u_lightDir",
    "u_dirColor",
    "u_ambient"
};


@interface GenericShader() {
    GLint     _vars[NUM_SVARIABLES];
    NSArray * _svTypes;
}
@end

@implementation GenericShader

-(id)initWithName:(NSString *)name andHeader:(NSString *)header;
{
    if( (self = [super initWithName:name andHeader:header]) )
    {
        for( int i = 0; i < sizeof(_vars)/sizeof(_vars[0]); i++ )
        {
            _vars[i] = SV_NONE;
        }
        [self use];
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
            NSLog(@"Can't find attr/uniform for (%d) %s in program %d", (int)type, __names[type],_program);
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

-(void)setNormalMat:(GLKMatrix3)normalMat
{
    [self.locations writeToLocation:[self location:sv_normalMat] type:TG_MATRIX3 data:normalMat.m];
    _normalMat = normalMat;
}

-(void)setLightDir:(GLKVector3)lightDir
{
    [self.locations writeToLocation:[self location:sv_lightDir] type:TG_VECTOR3 data:lightDir.v];
    _lightDir = lightDir;
}

-(void)setDirColor:(GLKVector3)dirColor
{
    [self.locations writeToLocation:[self location:sv_dirColor] type:TG_VECTOR3 data:dirColor.v];
    _dirColor = dirColor;
}

-(void)setColor:(GLKVector4)color
{
    [self.locations writeToLocation:[self location:sv_ucolor] type:TG_VECTOR4 data:color.v];
    _color = color;
}

-(void)setAmbient:(GLKVector3)ambient
{
    [self.locations writeToLocation:[self location:sv_ambient] type:TG_VECTOR3 data:ambient.v];
    _ambient = ambient;
}

@end
