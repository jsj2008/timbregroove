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
    gv_acolor = 0,
    gv_normal,
    gv_pos,
    gv_uv,
    
    GV_LAST_ATTR = gv_uv,
    
    gv_pvm, // projection-view-mat
    gv_sampler,
    gv_ucolor,
    
    gv_normalMat,
    gv_lightDir,
    gv_dirColor,
    gv_ambient,
    
    gv_time,
    
    gv_distortionPt, // vec3
    gv_distortionFactor, // float
    
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
