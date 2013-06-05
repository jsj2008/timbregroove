//
//  Butterfly.m
//  TimbreGroove
//
//  Created by victor on 5/31/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "MeshImportPainter.h"
#import "GridPlane.h"
#import "GenericShader.h"
#import "Material.h"
#import "Light.h"
#import "Material.h"


@interface Butterfly : MeshImportPainter
@end

@implementation Butterfly
-(void)createBuffer
{
    MeshBuffer * mb;
    mb = [GridPlane gridWithIndicesIntoNames:@[@(gv_pos),@(gv_normal)]];
    [self addBuffer:mb];
}

- (id)init
{
    self = [super init];
    if (self) {
        [self makeLights];
        [self setMaterials];
        self.position = (GLKVector3){ 0, 0, -20.0 };
        self.scale = (GLKVector3){ 20, 40, 0 };
    }
    return self;
}


-(void)setMaterials
{
    Material * material = [Material new];
    material.diffuse = (GLKVector4) { 0.5, 0.5, 1.0, 1 };
    material.ambient = (GLKVector4) {0,1,0,1};
    material.specular = (GLKVector4) { 1,1,1,1 };
    material.doSpecular = true;
    material.shininess = 1024;
    [self addShaderFeature:material];
}

-(void)makeLights
{
    Light * light = [Light new];
    light.ambient = (GLKVector4){ 1, 0, 0, 1 };
    Lights * lights = [Lights new];
    [lights addLight:light];
    self.lights = lights;
}

@end
