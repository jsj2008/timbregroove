//
//  TGGenericShader.m
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "GenericShader.h"
#import "Painter.h"

const char * _generic_shader_name = "generic";

#define SHADER_FILE_NAME _generic_shader_name

static const char * _generic_shader_var_names[NUM_GENERIC_VARIABLES] = {
    "a_position",
    "a_normal",
    "a_uv",
    "a_color",
    "a_boneWeights",
    
    "u_pvm",
    "u_mvm",
    "u_normalMat",

    "u_sampler",

    "u_jointMats",
    "u_jointInvMats",
    "u_numJoints",
    
    "u_material",
    "u_shininess",
    "u_doSpecular",
    
    "u_lightsEnabled",
    "u_lights[0].position",
    "u_lights[0].colors",
    "u_lights[0].attenuation",
    "u_lights[0].spotCutoffAngle",
    "u_lights[0].spotDirection",
    "u_lights[0].spotFalloffExponent",
    
    "u_lights[1].position",
    "u_lights[1].colors",
    "u_lights[1].attenuation",
    "u_lights[1].spotCutoffAngle",
    "u_lights[1].spotDirection",
    "u_lights[1].spotFalloffExponent",
    
    "u_time",
    
    "u_rippleSize",
    "u_ripplePt",
    "u_spotLocation",
    "u_spotIntensity"
    
};


@interface GenericShader() {
    NSArray * _svTypes;
}
@end

@implementation GenericShader

+(id)shader
{
    return [GenericShader shaderWithHeaders:nil];
}

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
    self.acceptMissingVars = true;
    return   [super initWithVertex: SHADER_FILE_NAME
                       andFragment: SHADER_FILE_NAME
                       andVarNames: _generic_shader_var_names
                       andNumNames: NUM_GENERIC_VARIABLES
                       andLastAttr: GV_LAST_ATTR
                        andHeaders: headers];
}

@end
