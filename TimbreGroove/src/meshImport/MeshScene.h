//
//  Mesh.h
//  aotkXML
//
//  Created by victor on 3/28/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  MeshGeometry  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

typedef enum _MeshSemanticKey {
    MSKPosition,
    MSKNormal,
    MSKUV,
    MSKColor,
    MSKBoneIndex,
    MSKBoneWeights,
    
    kNumMeshSemanticKeys
} MeshSemanticKey;


typedef struct _MeshGeometryBuffer {
    float *          data;
    int              offset;
    int              stride;
    int              numFloats;
    int              numElements;
    
    unsigned int *   indexData;
    int              numIndices;
} MeshGeometryBuffer;

@interface MeshGeometry : NSObject {
@public
    MeshGeometryBuffer _buffers[kNumMeshSemanticKeys];
}
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  SceneNode(s) @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

typedef enum _MeshSceneNodeType {
    MSNT_UNKNOWN_WTF,
    MSNT_Mesh,
    MSNT_Armature,
    MSNT_Camera,
    MSNT_Light
} MeshSceneNodeType;

@interface MeshSceneNode : NSObject {
@public
    MeshSceneNodeType     _type;
    NSString *            _name;
    NSString *            _sid;
    GLKMatrix4            _transform;
    NSMutableDictionary * _children;
}
@property (nonatomic) GLKMatrix4 transform;

-(void)addChild:(MeshSceneNode *)child name:(NSString *)name;
@end

@interface MeshSceneArmatureNode : MeshSceneNode {
@public
    GLKMatrix4   _world;
    GLKMatrix4   _invBindMatrix;
    GLKMatrix4   _invBindPoseMatrix;
    __weak MeshSceneArmatureNode * _parent;
    bool _translateHack;
}
-(GLKMatrix4)matrix;
@end

@class MeshSkinning;

@interface MeshSceneMeshNode : MeshSceneNode {
@public
    GLKVector3 _location;
    GLKVector3 _rotationX;
    GLKVector3 _rotationY;
    GLKVector3 _rotationZ;
    GLKVector3 _scale;
    
    MeshSkinning *          _skin;
    MeshGeometry *          _geometry;
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
    NSMutableArray      *   _animations;
    MeshSceneMeshNode *     _mesh;
    MeshSceneArmatureNode * _armatureTree;
}
@property (nonatomic,strong) NSString * fileName;
-(MeshGeometry *)getGeometry:(NSString *)name;
-(void)calcMatricies;
-(void)calcAnimationMatricies;
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  MeshSkinning @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@interface MeshSkinning : NSObject {
@public
    GLKMatrix4       _bindShapeMatrix;

    // Array of MeshNodeArmatureNodes that
    // directly influence vertices by
    // means of their transofrom mats
    NSMutableArray * _influencingJoints;

    // array of weight factors to be used to
    // influence vertices. Which weight(s)
    // apply to which vertex is determined
    // using the arrays below.
    float *          _weights;
    int              _numWeights;
    
    // one of these per vertex in the mesh
    // each short is the number of joints influencing
    // the vertex
    unsigned short * _influencingJointCounts;
    int              _numInfluencingJointCounts;

    // Packed array of dynamic length packets:
    //
    //  assuming _jointWOffset is 0 then:
    //    n number of indices into _influencingJoints
    //  followed by
    //    n number of indices into _weights
    //
    //  where 'n' is the current number at
    //  _influencingJointCounts
    //
    //  so assume you have a counter that starts at 0 and
    //  tracks the current position into _weightIndices
    //  called currPos:
    //
    //  for every v where v = 0 -> numberOfVertices in mesh:
    //
    //     numberOfJointsApplied = _influencingJointCounts[ v ]
    //
    //     for currPos -> currPos + numberOfJointsAppled
    //          joint:n  = _influencingJoints[ _weightIndices[ currPos + _jointWOffset ] ]
    //          weight:n =           _weights[ _weightIndices[ currPos + _weightFOffset ] ]
    //          outv:n += ((mesh[v] * skin->BSM) * joint:n->invBSM * joint:n->_transform ) * weight:n;
    //        ￼
    //
    unsigned short * _packedWeightIndices; 
    int              _numPackedWeightIndicies;

    int              _jointWOffset;
    int              _weightFOffset;
    
    MeshSceneArmatureNode * _bone;
    MeshGeometry *          _geometry;
    unsigned short *        _vectorIndex;
}

-(void)influence:(MeshGeometryBuffer *)buffer dest:(float *)dest;
@end


@interface MeshScene (Emitter)
-(void)emit;
@end