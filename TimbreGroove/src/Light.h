//
//  Light.h
//  TimbreGroove
//
//  Created by victor on 1/21/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//
#import "TGTypes.h"
#import "ShaderFeature.h"

@class Light;
@class Painter;

@interface Lights : ShaderBinder
-(id)initWithObject:(Painter *)object;
-(void)addLight:(Light *)light;
@end

/*
 from shader:
 
 struct Light {
 vec4   position;
 vec4   colors[CI_NUM_COLORS];
 vec3   attenuation;
 
 float spotCutoffAngle;
 vec3  spotDirection;
 float spotFalloffExponent;
 };
*/

typedef struct _ShaderLight {
    GLKVector4     position; // w == 0 ambient, 1 directional
    MaterialColors colors;
    GLKVector3     attenuation;
    
    // spot:
    float      spotCutoffAngle; // 0 means no spot
    GLKVector3 spotDirection;
    float      spotFalloffExponent;
} ShaderLight;

@interface Light : ShaderBinder
@property (nonatomic) GLKVector3 position;
@property (nonatomic) GLKVector3 attenuation;
@property (nonatomic) ShaderLight desc;
@property (nonatomic) bool directional;
@property (nonatomic) int lightNumber;
@end
