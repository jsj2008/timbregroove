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

@interface ButterflyBackground : Painter {
    float _rot;
}
@end
@implementation ButterflyBackground

- (id)init
{
    self = [super init];
    if (self) {
        self.position = (GLKVector3){ 0, 0, -15 };
        self.scale = (GLKVector3){ 20.0, 40.0, 0.0 };
    }
    return self;
}

-(void)update:(NSTimeInterval)dt
{
    self.rotation = (GLKVector3){ 0, GLKMathDegreesToRadians(30.0*_timer), 0 };
    [super update:dt];
}

-(void)createBuffer
{
    MeshBuffer * mb;
    
#define BOTTOM_SQ_COLOR (GLKVector4){ 0.0, 0.0, 1.0, 1.0 }
#define TOP_SQ_COLOR    (GLKVector4){ 0.8, 0.8, 1.0, 1.0 }
    
    static GLKVector4 colors[4] = {
        BOTTOM_SQ_COLOR,
        TOP_SQ_COLOR,
        BOTTOM_SQ_COLOR,
        TOP_SQ_COLOR
    };
    
    ColorBuffer * cb = [ColorBuffer new];
    [cb setDataWithRGBAs:(float *)colors numColors:4 indexIntoNames:gv_acolor];
    [self addBuffer:cb];
    
    mb = [GridPlane gridWithIndicesIntoNames:@[@(gv_pos),@(gv_normal)]];
//    mb = [GridPlane gridWithIndicesIntoNames:@[@(gv_pos)]];
    [self addBuffer:mb];
    
}

@end

@interface Butterfly : Painter // MeshImportPainter
@end

@implementation Butterfly

- (id)init
{
    self = [super init];
    if (self) {
        [self makeLights];
        [self appendChild:[ButterflyBackground new]];
    }
    return self;
}


-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    [super render:w h:h];
}

-(void)makeLights
{
    Light * light = [Light new];
    Lights * lights = [Lights new];
    [lights addLight:light];
    self.lights = lights;
}

@end
