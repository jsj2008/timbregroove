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

@interface SquishBoxAnimation : NSObject {
    float _initPos;
    float _targetPos;
    float _duration;
    TweenFunction _func;
    MeshSceneArmatureNode * _control;
    GLKMatrix4 _controlWorld;
}
@property (nonatomic) bool inAnimation;
-(id)initWithJoint:(MeshSceneArmatureNode *)joint;
@end

@implementation SquishBoxAnimation

-(id)initWithJoint:(MeshSceneArmatureNode *)joint

{
    self = [super init];
    if( self )
    {
        _control = joint;
        _controlWorld = [_control matrix];
        _initPos = -1.5;
        _targetPos = 1.0;
        _duration =  0.7;
        _func = kTweenEaseOutThrow;
    }
    return self;
}

-(NSTimeInterval)update:(NSTimeInterval)timer
{
    if( _inAnimation  )
    {
        if( ( timer < _duration) )
        {
            float delta = tweenFunc(_func, timer / _duration);
            float newZ = _initPos + ((_targetPos - _initPos) * delta);
            GLKMatrix4 mat = GLKMatrix4MakeTranslation(0, 0, newZ);
            _control->_transform = GLKMatrix4Multiply(_controlWorld, mat);
        }
        else
        {
            float t = _initPos;
            _initPos = _targetPos;
            _targetPos = t;
            if( _func == kTweenEaseOutThrow )
            {
                timer = 0;
                _func = kTweenEaseOutBounce;
            }
            else
            {
                _func = kTweenEaseOutThrow;
                _inAnimation = false;
            }
        }
    }
    
    return timer;
}
@end

@interface SquishBox : MeshImportPainter
@end

@implementation SquishBox {
    SquishBoxAnimation * _squish;
    bool _seenIt;
}

-(void)update:(NSTimeInterval)dt
{
    [super update:dt];
    if( !_seenIt )
    {
        Node3d * meshPainter = [self findMeshPainterWithName:@"BoxMesh"];
        meshPainter.rotation = (GLKVector3){ GLKMathDegreesToRadians(-90), 0, GLKMathDegreesToRadians(-50) };
        
        _squish  = [[SquishBoxAnimation alloc] initWithJoint:[self findJointWithName:@"jt_control"]];
        
        _seenIt = true;
    }
    
    if( _squish.inAnimation )
        _timer = [_squish update:_timer];
}


-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];
    
    putHere[@"Squish"] = [Parameter withBlock:^(CGPoint pt) {
        if( !_squish.inAnimation )
        {
            _squish.inAnimation = true;
            _timer = 0;
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
