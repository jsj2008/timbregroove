//
//  Spherey.m
//  TimbreGroove
//
//  Created by victor on 3/22/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Sphere.h"
#import "Scene.h"
#import "Names.h"
#import "GraphView.h"
#import "Light.h"
#import "Material.h"


@interface Spherey : Sphere
@end

@implementation Spherey {
    float _rotation;
}

-(id)wireUp
{    
    Light * light = [Light new];
    light.point = true;
    light.position = (GLKVector3){ -2, 1, 3 };
    light.spotDirection = (GLKVector3){ 2, -1, -1 };
    light.diffuse = (GLKVector4){ 0.5, 0.5, 0.5, 1 };
    light.attenuation = (GLKVector3){ 0, 0.2, 0 };
    
    [self.lights addLight:light];
    
    [super wireUp];
    self.position = (GLKVector3){0,0,0};
    self.scaleXYZ = 1.8;
    return self;
}

-(void)createShader
{
    [self addShaderFeature:[[Texture alloc] initWithFileName:@"moon.png"]];
    [super createShader];
}

-(void)update:(NSTimeInterval)dt
{
    _rotation += dt * 15.0;
    self.rotation = (GLKVector3){ 0, GLKMathDegreesToRadians(_rotation), 0 };
    [super update:dt];
}
@end
