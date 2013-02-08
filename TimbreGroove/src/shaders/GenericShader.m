//
//  TGGenericShader.m
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "GenericShader.h"
#import "Generic.h"
#import "Light.h"

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
    "u_ambient",
    "u_distortionPoint",
    "u_distortionFactor"
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

+(id)shaderWithIndicesIntoNames:(NSArray *)arr
{
    return [GenericShader shaderWithHeaders:[Generic getShaderHeaderWithIndicesIntoName:arr]];
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

- (void) prepareRender:(TG3dObject *)tgobj
{
    GenericBase * object = (GenericBase *)tgobj;
    
    GLKMatrix4 pvm = [object calcPVM];
    [self writeToLocation:gv_pvm type:TG_MATRIX4 data:pvm.m];
    
    if( object.light )
    {
        Light * light = object.light;
        
        GLKMatrix3 normalMat = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(pvm), NULL);
        [self writeToLocation:gv_normalMat type:TG_MATRIX3 data:normalMat.m];
        
        [self writeToLocation:gv_lightDir type:TG_VECTOR3 data:light.direction.v];
        [self writeToLocation:gv_dirColor type:TG_VECTOR3 data:light.dirColor.v];
        [self writeToLocation:gv_ambient  type:TG_VECTOR3 data:light.ambientColor.v];
    }
    
    if( object.useColor )
        [self writeToLocation:gv_ucolor type:TG_VECTOR4 data:object.color.v];
}

@end
