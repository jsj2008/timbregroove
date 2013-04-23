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

@interface Lights : NSObject<ShaderFeature>
-(id)initWithObject:(Painter *)object;
-(void)addLight:(Light *)light;
@end

/*
 position: 
    positive Z is toward you (facing into the phone)
 
    for directional light:
    while it may seem a little counter-intuitive, the further
    the light is one axis, the brigher that light will be
    from that direction. That's b/c that direction is overwhelming
    the other axis. e.g. if the light is at y:4000 then moving
    the light a little to the left x:-4 doesn't really change 
    much in that the vast majority of the light is coming from
    above.
 
 .w of position controls directional vs. point
    0         = directional - parallel, even light from infinity
    1 (non-0) = point - flows from a spot, decays using attenuation below
 
 spotCutoffAngle: non-zero puts a cone around the light (only used for point)
 
 attenuation: only applies to point/spot type lights
    in all cases below, 0 means let 100% of light through. Typically you 
    want to set ONE of x, y, or z to some value, the other two to 0.0. 
    Combining is possible. Mortality is certain. 
 
    TGB means: given that ambient/diffuse colors are all 1s, Things Go
               Black at (very) roughly the given value. (Anectodally speaking)
 
    attenuation.x := decay is constant. IOW, no matter how far the light is from 
                     the vector, it will be diminished by this much. TGB 6.5
 
    attenuation.y := decay is linear based on distance from vector. TGB distance * 0.3
 
    attenuation.z := decay is quadratic (whatever the fuck that means) based on
                     distance squared. TGB distance squared * 0.007
*/

typedef struct _ShaderLight {
    GLKVector4     position; 
    MaterialColors colors;
    GLKVector3     attenuation;
    
    // spot:
    float      spotCutoffAngle; // 0 means no spot
    GLKVector3 spotDirection;
    float      spotFalloffExponent;
} ShaderLight;


@interface Light : NSObject<ShaderFeature>
@property (nonatomic) GLKVector3 position;
@property (nonatomic) GLKVector3 rotation; // not sure about this
@property (nonatomic) GLKVector3 attenuation;
@property (nonatomic) GLKVector4 ambient;
@property (nonatomic) GLKVector4 diffuse;
@property (nonatomic) ShaderLight desc;
@property (nonatomic) bool point;
@property (nonatomic) int lightNumber;
@end
