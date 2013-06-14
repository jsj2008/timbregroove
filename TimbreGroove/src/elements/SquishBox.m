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
#import "Names.h"

#define NUM_ELEM(x) (sizeof(x)/sizeof(x[0]))

AnimationPathKeyFrame boxBouncePath[] = {
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

AnimationPath boxBounceAnimation = {
    "jt_front",
    boxBouncePath,
    NUM_ELEM(boxBouncePath)
};

AnimationClip boxBounceClip = {
    "boxBounce",
    &boxBounceAnimation,
    1
};

AnimationPathKeyFrame boxFlipPath[] = {
    {
        { 0, 0, 0 },
        { 90, 0, 0 },
        TIME_TO_FRAME(0.2),
        kTweenLinear// kTweenEaseInThrow
    },
    {
        { 0, 1.0, 0 },
        { 180, 0, 0 },
        TIME_TO_FRAME(0.1),
        kTweenLinear // kTweenEaseInThrow
    },
    {
        { 0, 1.0, 0 },
        { 270, 0, 0 },
        TIME_TO_FRAME(0.1),
        kTweenEaseInSine
    },
    {
        { 0, 0, 0 },
        { 360, 0, 0 },
        TIME_TO_FRAME(0.5),
        kTweenEaseOutSine
    }
};

AnimationPath boxFlipAnimation = {
    "jt_fixed",
    boxFlipPath,
    NUM_ELEM(boxFlipPath)
};

AnimationClip boxFlipClip = {
    "boxFlip",
    &boxFlipAnimation,
    1
};


@interface SquishBox : MeshImportPainter
@end

@implementation SquishBox {
    bool _seenIt;
    bool _isScrubbing;
}

-(void)update:(NSTimeInterval)dt
{
    if( !_seenIt )
    {
        AnimationBaker * baker = [AnimationBaker bakerWithClip:&boxBounceClip];
        NSArray * animations = [baker bake:self];
        [self addAnimation:@(boxBounceClip.name) animations:animations];
        baker = [AnimationBaker bakerWithClip:&boxFlipClip];
        animations = [baker bake:self];
        [self addAnimation:@(boxFlipClip.name) animations:animations];
        _seenIt = true;
    }
    [super update:dt];
}


-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];
    
    putHere[@"Squish"] = [Parameter withBlock:^(CGPoint pt) {
        if( pt.y > 0 )
            [self queueAnimation:@(boxBounceClip.name)];
        else
            [self queueAnimation:@(boxFlipClip.name)];
    }];
    
    putHere[@"Scrub"] = [Parameter withBlock:^(float amt) {
        _isScrubbing = true;
        [self scrubAnimation:@(boxFlipClip.name) scrubPercent:amt];
    }];
    
    putHere[@"ScrubDone"] = [Parameter withBlock:^(int type) {
        if( _isScrubbing )
        {
            [self resetAnimation:@(boxFlipClip.name)];
            _isScrubbing = false;
        }
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
