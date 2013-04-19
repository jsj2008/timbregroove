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
    
    gv_pvm, // projection-view-mat
    
    // Texture
    gv_sampler,
    
    // ColorMaterial
    gv_ucolor,
    
    // Light
    gv_normalMat,
    gv_lightDir,
    gv_lightPosition,
    
    // Ambient material
    gv_dirColor,
    gv_ambient,
    
    // Phong material
    gv_phongColors,
    gv_phoneValues,
    
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
