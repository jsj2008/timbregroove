//
//  MeshSceneAnimation.h
//  TimbreGroove
//
//  Created by victor on 6/13/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MeshSceneNode;
@class MeshSceneArmatureNode;
@class MeshImportPainter;

@interface MeshAnimation : NSObject {
@public
    float *         _keyFrames;
    int             _numFrames;
    GLKMatrix4 *    _transforms;
    
    // block?
    MeshSceneNode * _target;
    NSString *      _property;
}
@property (nonatomic) bool loop;
-(bool)update:(NSTimeInterval)dt;
@end

#define ANIMATION_FRAME_PER_SECOND 24.0
#define FRAME_LEN ( 1.0 / ANIMATION_FRAME_PER_SECOND )
#define TIME_TO_FRAME(t) ((unsigned int)( t * ANIMATION_FRAME_PER_SECOND ))

typedef struct _AnimationPathKeyFrame {
    GLKVector3    targetPos;
    GLKVector3    targetRot;
    unsigned int  numFrames; // determines lengths in time
    TweenFunction function;
} AnimationPathKeyFrame;

typedef struct _AnimationPath {
    const char * targetNodeName;
    AnimationPathKeyFrame   * path;
    NSUInteger numFramesInPath;
} AnimationPath;

typedef struct _AnimationClip {
    const char * name;
    AnimationPath * paths;
    NSUInteger numPaths;
} AnimationClip;

@interface AnimationBaker : NSObject
+(id)bakerWithClip:(AnimationClip *)clip;
-(NSArray *)bake:(MeshImportPainter *)importer;
@end

