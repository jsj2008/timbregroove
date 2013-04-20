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
    gv_boneIndex,
    gv_boneWeights,
    
    GV_LAST_ATTR = gv_boneWeights,
    
    gv_pvm,        // projection-view-mat
    gv_mvm,        // model view matrix
    gv_normalMat,  // normals matrix
    
    // Texture
    gv_sampler,
    
    // Material
    gv_material,
    gv_shininess,
    gv_doSpecular,
    
    // Light
    gv_lightingEnabled,
    gv_lights,
    gv_light_1 = gv_lights,
    gv_light_2 = gv_lights + 1,
    GV_NUM_LIGHTS = gv_light_2,
    
    
    // ShaderTimer
    gv_time,

    gv_rippleSize,
    gv_ripplePt,
    gv_spotLocation,
    gv_spotIntensity,
    
    NUM_GENERIC_VARIABLES
    
} GenericVariables;

@interface GenericShader : Shader

+(id)shader;
+(id)shaderWithHeaders:(NSString *)headers;
-(id)initWithHeaders:(NSString *)headers;

@end
