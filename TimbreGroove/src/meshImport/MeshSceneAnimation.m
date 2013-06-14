//
//  MeshSceneAnimation.m
//  TimbreGroove
//
//  Created by victor on 6/13/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "MeshScene.h"
#import "MeshImportPainter.h"
#import "Log.h"

@implementation MeshAnimation {
    NSTimeInterval  _clock;
    int             _nextFrame;
    unsigned int    _scrubFrame;
    int             _scrubDir;
}

-(void)dealloc
{
    free(_keyFrames);
    free(_transforms);
    TGLog(LLObjLifetime, @"%@ released", self);
}

-(bool)update:(NSTimeInterval)dt
{
    if( _nextFrame == _numFrames )
    {
        if( !_loop )
            return true;
        [self reset];
    }
    
    _clock += dt;    
    if( _clock >= _keyFrames[_nextFrame] )
        _target->_transform = _transforms[_nextFrame++];
 
    return false;
}

-(void)scrub:(float)percent
{
    int scrubDir = 1;
    if( percent < 0 )
        scrubDir = -1;
    if( _scrubDir && (scrubDir != _scrubDir) )
        _scrubFrame = _nextFrame;
    _scrubDir = scrubDir;
        
    unsigned int frameDelta = (unsigned int)( _numFrames * percent );
    _nextFrame = _scrubFrame + frameDelta;
    if( _nextFrame >= _numFrames )
        _nextFrame %= _numFrames;
    else if( _nextFrame < 0 )
        _nextFrame += _numFrames;
    TGLog( LLGestureStuff, @"Scrubbing: %d+%d = %d out of %d",
          _scrubFrame, frameDelta, _nextFrame, _numFrames );
    _target->_transform = _transforms[_nextFrame];
}

-(void)reset
{
    _scrubFrame = _nextFrame;
    _scrubDir = 0;
    _clock = 0;
    _nextFrame = 0;
    TGLog( LLGestureStuff, @"Animation reset: scrub frame: %d", _scrubFrame );
}
@end

@interface AnimationBaker : NSObject
+(id)bakerWithClip:(AnimationClip *)clip;
-(NSArray *)bake:(id<JointDictionary>)importer
 framesPerSecond:(unsigned int)fps;
@end

/*==============================================================================*/

@implementation Animation {
    NSArray * _animations;
}

-(id)initWithClip:(AnimationClip *)clip
        jointDict:(id<JointDictionary>)jointDict
              fps:(unsigned int)fps
{
    self = [super init];
    if( self )
    {
        AnimationBaker * baker = [AnimationBaker bakerWithClip:clip];
        _animations = [baker bake:jointDict framesPerSecond:fps];
        _name = @(clip->name);
    }
    return self;
}

+(id)withClip:(AnimationClip *)clip
    jointDict:(id<JointDictionary>)jointDict
          fps:(unsigned int)fps
{
    return [[Animation alloc] initWithClip:clip jointDict:jointDict fps:fps];
}

-(id)initWithAnimations:(NSArray *)animations // MeshAnimation *
                   name:(NSString *)name
{
    self = [super init];
    if( self )
    {
        _animations = animations;
        _name = name;
    }
    return self;
}

+(id)withAnimations:(NSArray *)animations // MeshAnimation *
               name:(NSString *)name
{
    return [[Animation alloc] initWithAnimations:animations name:name];
}

-(bool)update:(NSTimeInterval)dt
{
    bool done = true;
    for ( MeshAnimation * animation in _animations )
        done = [animation update:dt] && done;
    return done;
}

-(void)scrub:(float)scrubPercent
{
    for( MeshAnimation * animation in _animations )
        [animation scrub:scrubPercent];
}

-(void)reset
{
    for( MeshAnimation * animation in _animations )
        [animation reset];
}


@end

/*==============================================================================*/

@implementation AnimationBaker {
    AnimationClip * _clip;
}

+(id)bakerWithClip:(AnimationClip *)clip
{
    return [[AnimationBaker alloc] init:clip];
}

-(id)init:(AnimationClip *)clip
{
    self = [super init];
    if(self) {
        _clip = clip;
    }
    return self;
}

-(NSArray *)bake:(MeshImportPainter *)importer
 framesPerSecond:(unsigned int)fps
{
    NSMutableArray * arr = [NSMutableArray new];
    for( int i = 0; i < _clip->numPaths; i++ )
    {
        AnimationPath * path = _clip->paths + i;
        MeshSceneArmatureNode * joint = [importer findJointWithName:@(path->targetNodeName)];
        MeshAnimation * animation = [self bakePath:path joint:joint framesPerSecond:fps];
        [arr addObject:animation];
    }
    return arr;
}

-(MeshAnimation *)bakePath:(AnimationPath *)path
                     joint:(MeshSceneArmatureNode*)joint
           framesPerSecond:(unsigned int)fps
{
    unsigned int totalFrames = 0;
    
    for( int i = 0; i < path->numFramesInPath; i++ )
    {
        float time = (path->path + i)->timeLen;
        totalFrames += TIME_TO_FRAME(time, fps);
    }
    
    GLKMatrix4 * transforms_buffer    = malloc( sizeof(GLKMatrix4) * totalFrames);
    float *      keyFrameTimes_buffer = malloc( sizeof(float) * totalFrames );
    
    GLKMatrix4 *            pTransforms    = transforms_buffer;
    float *                 pKeyFrameTimes = keyFrameTimes_buffer;
    AnimationPathKeyFrame * pKeyFrame      = path->path;
    
    unsigned int frameCounter = 0;
    
    GLKVector3 pos = (GLKVector3){ 0, 0, 0 }; // _initPos;
    GLKVector3 rot = (GLKVector3){ 0, 0, 0 };
    for( int currentKeyFrame = 0; currentKeyFrame < path->numFramesInPath; currentKeyFrame++ )
    {
        unsigned int numFrames = TIME_TO_FRAME(pKeyFrame->timeLen, fps);
        GLKVector3   tpos      = pKeyFrame->targetPos;
        GLKVector3   trot      = pKeyFrame->targetRot;
        
        GLKVector3 newPos;
        GLKVector3 newRot;
        
        for( int f = 0; f < numFrames; f++ )
        {
            float delta = tweenFunc(pKeyFrame->function, (float)(f+1) / (float)numFrames);
            newPos.x = pos.x + ( (tpos.x - pos.x) * delta);
            newPos.y = pos.y + ( (tpos.y - pos.y) * delta);
            newPos.z = pos.z + ( (tpos.z - pos.z) * delta);
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
            *pTransforms++    = transform;
            *pKeyFrameTimes++ = ++frameCounter * FRAME_LEN(fps);
        }
        
        pos = newPos;
        rot = newRot;
        ++pKeyFrame;
    }
    
    MeshAnimation * animation = [[MeshAnimation alloc] init];
    animation->_numFrames  = totalFrames;
    animation->_keyFrames  = keyFrameTimes_buffer;
    animation->_transforms = transforms_buffer;
    animation->_target     = joint;
    
    return animation;
}

@end

/*==============================================================================*/

@implementation AnimationDictionary {
    NSMutableDictionary * _animations;
}

-(void)addClip:(Animation *)animation
{
    if( !_animations )
        _animations = [NSMutableDictionary new];
    _animations[ animation.name ] = animation;
}
-(void)queueClip:(NSString *)name
{
    Animation * animation = _animations[name];
    [animation reset];
    _current = animation;
}

-(Animation *)clip:(NSString *)name
{
    return _animations[name];
}

-(void)update:(NSTimeInterval)dt
{
    if( _current )
        [_current update:dt];
}
@end