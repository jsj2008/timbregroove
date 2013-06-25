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

typedef struct _AnimationBezierSpec
{
    float * input; // timing
    float * output; // target value
    float * out_tangent; // control point 0
    float * in_tangent; //  control point 1 (at index+1)
} AnimationBezierSpec;

typedef enum _AnimationType {
    AT_baked,
    AT_bezier
} AnimationType;

@interface MeshAnimation : NSObject {
@public
    AnimationType   _type;
    float *         _keyFrames;
    int             _numFrames;
    GLKMatrix4 *    _transforms;
    
    AnimationBezierSpec _specX;
    AnimationBezierSpec _specY;
    AnimationBezierSpec _specZ;
    float * _bezBuffer;
    
    MeshSceneNode * _target;
    NSString *      _property;
}
@property (nonatomic) bool loop;
@end

@protocol JointDictionary <NSObject>
-(MeshSceneArmatureNode *)findJointWithName:(NSString *)name;
@end


#define ANIMATION_FRAME_PER_SECOND 24.0
#define FRAME_LEN(fps) ( 1.0 / fps )
#define TIME_TO_FRAME(t,fps) ((unsigned int)( t * fps ))

typedef struct _AnimationPathKeyFrame {
    GLKVector3    targetPos;
    GLKVector3    targetRot;
    float         timeLen;
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

@interface Animation : NSObject
+(id)withClip:(AnimationClip *)clip
    jointDict:(id<JointDictionary>)jointDict
          fps:(unsigned int)fps;
+(id)withAnimations:(NSArray *)animations // MeshAnimation *
               name:(NSString *)name;
@property (nonatomic,strong) NSString * name;
-(bool)update:(NSTimeInterval)dt;
-(void)scrub:(float)scrubPercent; // -0.1 <-> 0.1
-(void)reset;
@end


@interface AnimationDictionary : NSObject
-(void)addClip:(Animation *)animation;
-(void)queueClip:(NSString *)name;
-(void)update:(NSTimeInterval)dt;
@property (nonatomic,strong) Animation * current;
-(Animation *)clip:(NSString *)name;
@end
