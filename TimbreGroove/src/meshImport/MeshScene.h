//
//  Mesh.h
//  aotkXML
//
//  Created by victor on 3/28/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "TGTypes.h"
#import "GenericShader.h"

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  MeshGeometry  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@interface MeshGeometry : NSObject {
@public
    NSString *   _name;
    float *      _buffer;
    VertexStride _strides[GV_LAST_ATTR];
    unsigned int _numStrides;
    unsigned int _numVertices;
    NSString *   _materialName;
    bool         _hasBones;
}

@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  SceneNode(s) @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

typedef enum _MeshSceneNodeType {
    MSNT_GroupNode,
    MSNT_Mesh = 1,
    MSNT_SkinnedMesh = 1 << 1,
    MSNT_SomeKindaMeshWereIn = MSNT_Mesh | MSNT_SkinnedMesh,
    MSNT_Armature = 1 << 2,
    MSNT_Camera = 1 << 3,
    MSNT_Light = 1 << 4
} MeshSceneNodeType;

@interface MeshSceneNode : NSObject {
@public
    MeshSceneNodeType     _type;
    NSString *            _name;
    NSString *            _sid;
    GLKMatrix4            _transform;
    GLKMatrix4             _world;
    NSMutableDictionary * _children;
    bool                  _animated;
    __weak MeshSceneNode* _parent;
}
@property (nonatomic) GLKMatrix4 transform;

-(void)addChild:(MeshSceneNode *)child name:(NSString *)name;
-(GLKMatrix4)matrix;
@end

//------- Joint
@interface MeshSceneArmatureNode : MeshSceneNode {
@public
    GLKMatrix4   _invBindMatrix;
}
@end

//------- Mesh
@interface MeshSceneMeshNode : MeshSceneNode {
@public
    GLKVector3 _location;
    GLKVector3 _rotationX;
    GLKVector3 _rotationY;
    GLKVector3 _rotationZ;
    GLKVector3 _scale;
    
    NSMutableArray *  _influencingJoints;
    NSDictionary *    _materials;
    NSArray *         _geometries;
}
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@  MeshAnimation  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@interface MeshAnimation : NSObject {
@public
    float *         _keyFrames;
    int             _numFrames;
    GLKMatrix4 *    _transforms;
    
    NSTimeInterval  _clock;
    unsigned int    _nextFrame;
    
    // block?
    MeshSceneNode * _target;
    NSString *      _property;
}
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  Mesh  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@interface MeshScene : NSObject {
@public
    NSArray  * _animations;
    NSArray  * _meshes;
    NSArray  * _allJoints;
}
@property (nonatomic,strong) NSString * fileName;
-(void)calcMatricies;
-(void)calcAnimationMatricies;
@end

@interface MeshScene (Emitter)
-(void)emit;
@end
