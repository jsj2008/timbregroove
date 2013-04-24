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

@class MeshSkinning;

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  MeshMaterial  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@interface MeshMaterial : NSObject {
@public
    NSString * _name;
    MaterialColors _colors;
    float _shininess;
    bool _doSpecular;
    NSString * _textureFileName;
}
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  MeshGeometry  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

// These conviently and coincidentally match up
// to gv_* enum in GenericShader.h

typedef enum _MeshSemanticKey {
    MSKPosition,
    MSKNormal,
    MSKUV,
    MSKColor,
    MSKBoneIndex,
    MSKBoneWeights,
    
    kNumMeshSemanticKeys
} MeshSemanticKey;

@interface MeshGeometry : NSObject {
@public
    NSString *   _name;
    float *      _buffer;
    VertexStride _strides[kNumMeshSemanticKeys];
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
    
    MeshSkinning *  _skin;
    NSDictionary *  _materials;
    NSArray *       _geometries;
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
    NSArray  * _joints;
}
@property (nonatomic,strong) NSString * fileName;
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
    unsigned short *        _vectorIndex;
}

//-(void)influence:(MeshGeometryBuffer *)buffer dest:(float *)dest;
@end


@interface MeshScene (Emitter)
-(void)emit;
@end
