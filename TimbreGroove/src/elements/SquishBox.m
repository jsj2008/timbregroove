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

typedef struct _KeyFrame {
    GLKVector3    targetPos;
    GLKVector3    targetRot;
    float         duration;
    TweenFunction function;
} KeyFrame;

@interface AnimationBaker : NSObject {
    MeshSceneArmatureNode * _joint;
    KeyFrame *              _keyFrames;
    unsigned int            _numKeyFrames;

    GLKVector3              _initPos;
    GLKVector3              _initRot;

}

-(MeshAnimation *)bake;
@end

@implementation AnimationBaker

-(id)initWithStuff:(MeshSceneArmatureNode *)joint
            frames:(KeyFrame *)frames
         numFrames:(unsigned int)numFrames
           initPos:(GLKVector3)initPos
           initRot:(GLKVector3)initRot
{
    self = [super init];
    if( self )
    {
        _joint = joint;
        _keyFrames = frames;
        _numKeyFrames = numFrames;
        _initPos = initPos;
        _initRot = initRot;
    }
    return self;
}

#define FRAME_LEN ( 1.0 / 24.0 )

-(MeshAnimation *)bake
{
    float totalTime = 0;
    
    for( int i = 0; i < _numKeyFrames; i++ )
    {
        totalTime += (_keyFrames + i)->duration;
    }
    
    unsigned int totalKeyFrames = (unsigned int) floorf(totalTime / FRAME_LEN );
    GLKMatrix4 * transforms = malloc( sizeof(GLKMatrix4) * totalKeyFrames);
    float * keyFrameTimes = malloc( sizeof(float) * totalKeyFrames );
    
    unsigned int currentFrame = 0;
    
    for( int i = 0; i < _numKeyFrames; i++ )
    {
        KeyFrame * keyFrame = _keyFrames + i;
        unsigned int numFrames = (unsigned int) floorf( keyFrame->duration / FRAME_LEN ) + 1;
        GLKVector3 tpos = keyFrame->targetPos;
        GLKVector3 trot = keyFrame->targetRot;
        float currentTime = 0;
        GLKVector3 pos = _initPos;
        GLKVector3 rot = _initRot;
        for( int i = 0; i < numFrames; i++, currentFrame++ )
        {
            currentTime += FRAME_LEN;
            if( currentTime > keyFrame->duration )
                currentTime = keyFrame->duration;
            float delta = tweenFunc(keyFrame->function, currentTime / keyFrame->duration);
            GLKVector3 newPos;
            newPos.x = pos.x + ( (tpos.x - pos.x) * delta);
            newPos.y = pos.y + ( (tpos.y - pos.y) * delta);
            newPos.z = pos.z + ( (tpos.z - pos.z) * delta);
            GLKVector3 newRot = _initRot;
            newRot.z = rot.z + ( (trot.z - rot.z) * delta);
            GLKMatrix4 transform = GLKMatrix4MakeTranslation(newPos.x, newPos.y, newPos.z );
            if( trot.x )
            {
                newRot.x = rot.x + ( (trot.x - rot.x) * delta);
                transform = GLKMatrix4Rotate(transform, GLKMathDegreesToRadians(newRot.x), 1, 0, 0);
            }
            if( trot.y )
            {
                newRot.y = rot.y + ( (trot.y - rot.y) * delta);
                transform = GLKMatrix4Rotate(transform, GLKMathDegreesToRadians(newRot.y), 0, 1, 0);
            }
            if( trot.z )
            {
                newRot.z = rot.z + ( (trot.z - rot.z) * delta);
                transform = GLKMatrix4Rotate(transform, GLKMathDegreesToRadians(newRot.z), 0, 0, 1);
            }
            *(transforms + currentFrame) = transform;
            *(keyFrameTimes + currentFrame) = currentTime;
        }
    }
    
    MeshAnimation * animation = [[MeshAnimation alloc] init];
    animation->_keyFrames  = keyFrameTimes;
    animation->_numFrames  = totalKeyFrames;
    animation->_transforms = transforms;
    animation->_target     = _joint;
    
    return animation;
}

@end

KeyFrame boxAnimation[] = {
    {
        { 0, 0, 2.0 },
        { 0, 0, 0 },
        1.2,
        kTweenEaseInThrow
    },
    {
        { 0, 0, 0.75 },
        { 0, 0, 0 },
        3.2,
        kTweenEaseOutBounce
    }
};

@interface SquishBox : MeshImportPainter
@end

@implementation SquishBox {
    bool _seenIt;
}

-(void)update:(NSTimeInterval)dt
{
    [super update:dt];
    if( !_seenIt )
    {
        Node3d * meshPainter = [self findMeshPainterWithName:@"BoxMesh"];
        meshPainter.rotation = (GLKVector3){ GLKMathDegreesToRadians(-90), 0, GLKMathDegreesToRadians(-50) };
        
        
        MeshSceneArmatureNode * joint = [self findJointWithName:@"jt_front"];
        AnimationBaker * baker = [[AnimationBaker alloc] initWithStuff:joint
                                                                frames:boxAnimation
                                                             numFrames:2
                                                               initPos:(GLKVector3){ 0, 0, 0.75 }
                                                               initRot:(GLKVector3){ 0, 0, 0 }];
        
        
        MeshAnimation * animation = [baker bake];
        NSMutableArray * arr;
        _animations = nil;
        if( _animations )
            arr = [NSMutableArray arrayWithArray:_animations];
        else
            arr = [NSMutableArray new];

        [arr addObject:animation];
        _animations = arr;
        
        _seenIt = true;
    }
    
}


-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];
    
    putHere[@"Squish"] = [Parameter withBlock:^(CGPoint pt) {
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
