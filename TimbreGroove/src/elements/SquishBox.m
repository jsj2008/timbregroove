//
//  SquishBox.m
//  TimbreGroove
//
//  Created by victor on 6/6/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "MeshImportPainter.h"
#import "MeshScene.h"
#import "Tween.h"
#import "Camera.h"
#import "Light.h"


AnimationPathKeyFrame boxPath[] = {
    {
        { 0, 1.75, 0 },
        { 0, 0, 0 },
        TIME_TO_FRAME(0.5),
        kTweenEaseOutSine // kTweenEaseInThrow
    },
    {
        { 0, 0, 0 },
        { 0, 0, 0 },
        TIME_TO_FRAME(1.3),
        kTweenEaseOutBounce
    }
};

AnimationPath boxAnimation = {
    "jt_front",
    boxPath,
    2
};

AnimationClip boxClip = {
    "boxBounce",
    &boxAnimation,
    1
};

@interface SquishBox : MeshImportPainter
@end

@implementation SquishBox {
    bool _seenIt;
}

-(void)update:(NSTimeInterval)dt
{
    if( !_seenIt )
    {
        AnimationBaker * baker = [AnimationBaker bakerWithClip:&boxClip];
        NSArray * animations = [baker bake:self];
        [self addAnimation:@(boxClip.name) animations:animations];
        _seenIt = true;
    }
    [super update:dt];
}


-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];
    
    putHere[@"Squish"] = [Parameter withBlock:^(CGPoint pt) {
        [self queueAnimation:@(boxClip.name)];
    }];
}

-(void)makeLights
{
    Lights * lights = [Lights new];

    Light * light;
    GLKVector3 pos;
    
    light = [Light new];
    pos = light.position;
    pos.y = 4.5;
    pos.x = 4.0;
    pos.z = 0;
    light.position = pos;
    light.point = true;
    light.attenuation = (GLKVector3){ 0.1, 0, 0 };
    [lights addLight:light];

    light = [Light new];
    pos = light.position;
    pos.y = 1.5;
    pos.z = 3.3;
    light.position = pos;
    [lights addLight:light];

    self.lights = lights;
}


@end
