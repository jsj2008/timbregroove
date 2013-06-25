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

AnimationPathKeyFrame boxBouncePath[] = {
    {
        { 0, 1.0, 0 },
        { 0, 0, 0 },
        (0.5),
        kTweenEaseOutSine // kTweenEaseInThrow
    },
    {
        { 0, 0.77, 0 },
        { 0, 0, 0 },
        (1.3),
        kTweenEaseOutBounce
    },
    {
        { 0, 0.3, 0 },
        { 0, 0, 0 },
        (0.1),
        kTweenEaseInSine
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
        { 0, 0, -1.0 },
        { 90, 0, 0 },
        (0.2),
        kTweenLinear// kTweenEaseInThrow
    },
    {
        { 0, 1.0, -1.5 },
        { 180, 0, 0 },
        (0.1),
        kTweenLinear // kTweenEaseInThrow
    },
    {
        { 0, 1.0, -1.0 },
        { 270, 0, 0 },
        (0.1),
        kTweenEaseInSine
    },
    {
        { 0, 0, 0 },
        { 360, 0, 0 },
        (0.5),
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
    Animation * _scrubber;
}

-(void)update:(NSTimeInterval)dt
{
    if( !_seenIt )
    {
        [self.animations addClip:[Animation withClip:&boxBounceClip jointDict:self fps:ANIMATION_FRAME_PER_SECOND]];
        [self.animations addClip:[Animation withClip:&boxFlipClip   jointDict:self fps:ANIMATION_FRAME_PER_SECOND]];
        _seenIt = true;
    }
    [super update:dt];
}


-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];
    
    putHere[@"Squish"] = [Parameter withBlock:^(CGPoint pt) {
        NSString * name = nil;
        if( pt.y > 0 )
            name = @(boxBounceClip.name);
        else
            name = @(boxFlipClip.name);
        [self.animations queueClip:name];
    }];
    
    putHere[@"Scrub"] = [Parameter withBlock:^(float amt) {
        if( !_scrubber )
            _scrubber = [Animation withClip:&boxFlipClip jointDict:self fps:110];
        [_scrubber scrub:amt];
    }];
    
    putHere[@"ScrubDone"] = [Parameter withBlock:^(int type) {
        if( _scrubber )
            [_scrubber reset];
    }];
}

-(void)makeLights
{
    Lights * lights = [Lights new];

    Light * light;
    GLKVector3 pos;
    
#if 1
    light = [Light new];
    pos = light.position;
    pos.y = 1.0;
    pos.x = 1.0;
    pos.z = 3.0;
    light.position = pos;
    light.point = true;
    light.attenuation = (GLKVector3){ 0.18, 0, 0 };
    light.enableParameters = true;
    [lights addLight:light];
#endif
    
#if 0
    light = [Light new];
    pos = light.position;
    pos.x =  1.0;
    pos.y = -1.0;
    pos.z =  3.0;
    light.position = pos;
    [lights addLight:light];
#endif
    
   self.lights = lights;
}


@end
