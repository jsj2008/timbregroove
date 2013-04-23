//
//  TGGenericShader.h
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGTypes.h"
#import "Shader.h"

typedef enum {
    gv_pos = 0,
    gv_normal,
    gv_uv,
    gv_acolor,
    gv_boneWeights,
    gv_boneIndex,
    
    GV_LAST_ATTR = gv_boneIndex,
    
    gv_pvm,        // projection-view-mat
    gv_mvm,        // model view matrix
    gv_normalMat,  // normals matrix
    
    // Texture
    gv_sampler,
    
    // Skinning
    gv_jointMats,
    gv_jointInvMats,
    gv_numJoints,
    
    // Material
    gv_material,
    gv_shininess,
    gv_doSpecular,
    
    // Light
    gv_lightsEnabled,
    gv_lights0_position,
    gv_lights0_colors,
    gv_lights0_attenuation,
    gv_lights0_spotCutoffAngle,
    gv_lights0_spotDirection,
    gv_lights0_spotFalloffExponent,
    
    gv_lights1_position,
    gv_lights1_colors,
    gv_lights1_attenuation,
    gv_lights1_spotCutoffAngle,
    gv_lights1_spotDirection,
    gv_lights1_spotFalloffExponent,
    
    
    // ShaderTimer
    gv_time,

    gv_rippleSize,
    gv_ripplePt,
    gv_spotLocation,
    gv_spotIntensity,
    
    NUM_GENERIC_VARIABLES
    
} GenericVariables;

#define LIGHT_STRUCT_NUM_ELEMENTS 6

@interface GenericShader : Shader

+(id)shader;
+(id)shaderWithHeaders:(NSString *)headers;
-(id)initWithHeaders:(NSString *)headers;

@end
