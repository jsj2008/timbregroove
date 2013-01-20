//
//  TGGenericShader.m
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "GenericShader.h"
#import "Generic.h"

const char * _generic_shader_name = "generic";

#define SHADER_FILE_NAME _generic_shader_name

static const char * _generic_shader_var_names[NUM_GENERIC_VARIABLES] = {
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
    NSArray * _svTypes;
}
@end

@implementation GenericShader


+(id)shaderWithHeaders:(NSString *)headers
{
    Shader * shader = [Shader shaderFromPoolWithVertex: SHADER_FILE_NAME
                                           andFragment: SHADER_FILE_NAME
                                           andVarNames: _generic_shader_var_names
                                           andNumNames: NUM_GENERIC_VARIABLES
                                           andLastAttr: GV_LAST_ATTR
                                            andHeaders: headers];
    if( !shader )
        shader = [[GenericShader alloc] initWithHeaders:headers];

    return shader;
}

-(id)initWithHeaders:(NSString *)headers
{
    // TODO: deal with different headers requiring different names to be passed in
    //
    self.acceptMissingVars = true;
    return   [super initWithVertex: SHADER_FILE_NAME
                       andFragment: SHADER_FILE_NAME
                       andVarNames: _generic_shader_var_names
                       andNumNames: NUM_GENERIC_VARIABLES
                       andLastAttr: GV_LAST_ATTR
                        andHeaders: headers];
}

-(void)setPvm:(GLKMatrix4)pvm
{
    [self writeToLocation:gv_pvm type:TG_MATRIX4 data:pvm.m];
    _pvm = pvm;
}

-(void)setNormalMat:(GLKMatrix3)normalMat
{
    [self writeToLocation:gv_normalMat type:TG_MATRIX3 data:normalMat.m];
    _normalMat = normalMat;
}

-(void)setLightDir:(GLKVector3)lightDir
{
    [self writeToLocation:gv_lightDir type:TG_VECTOR3 data:lightDir.v];
    _lightDir = lightDir;
}

-(void)setDirColor:(GLKVector3)dirColor
{
    [self writeToLocation:gv_dirColor type:TG_VECTOR3 data:dirColor.v];
    _dirColor = dirColor;
}

-(void)setColor:(GLKVector4)color
{
    [self writeToLocation:gv_ucolor type:TG_VECTOR4 data:color.v];
    _color = color;
}

-(void)setAmbient:(GLKVector3)ambient
{
    [self writeToLocation:gv_ambient type:TG_VECTOR3 data:ambient.v];
    _ambient = ambient;
}

- (void) prepareRender:(TG3dObject *)tgobj
{
    GenericBase * object = (GenericBase *)tgobj;
    
    GLKMatrix4 pvm = [object calcPVM];
    self.pvm = pvm;
    
    if( object.lighting )
    {
        self.normalMat = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(pvm), NULL);
        self.lightDir  = object.lightDir;
        self.dirColor  = object.dirColor;
        self.ambient   = object.ambient;
    }
    
    if( object.useColor )
        self.color = object.color;
}

@end
