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
    unsigned int    _nextFrame;
}

-(void)dealloc
{
    free(_keyFrames);
    free(_transforms);
    TGLog(LLObjLifetime, @"%@ released", self);
}

-(bool)update:(NSTimeInterval)dt
{
    _clock += dt;
    
    if( _clock >= _keyFrames[_nextFrame] )
    {
        _target->_transform = _transforms[_nextFrame];
        
        ++_nextFrame;
        if( _nextFrame == _numFrames )
        {
            _clock = 0;
            _nextFrame = 0;
            if( !_loop )
                return true;
        }
    }
 
    return false;
}
@end

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
{
    NSMutableArray * arr = [NSMutableArray new];
    for( int i = 0; i < _clip->numPaths; i++ )
    {
        AnimationPath * path = _clip->paths + i;
        MeshSceneArmatureNode * joint = [importer findJointWithName:@(path->targetNodeName)];
        MeshAnimation * animation = [self bakePath:path joint:joint];
        [arr addObject:animation];
    }
    return arr;
}

-(MeshAnimation *)bakePath:(AnimationPath *)path
                     joint:(MeshSceneArmatureNode*)joint
{
    unsigned int totalFrames = 0;
    
    for( int i = 0; i < path->numFramesInPath; i++ )
    {
        totalFrames += (path->path + i)->numFrames;
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
        unsigned int numFrames = pKeyFrame->numFrames;
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
            *pKeyFrameTimes++ = ++frameCounter * FRAME_LEN;
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
