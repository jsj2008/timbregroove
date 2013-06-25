//
//  ColladaParserInternals.h
//  TimbreGroove
//
//  Created by victor on 4/29/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "GenericShader.h"
#import "MeshScene.h"

#define kNumMeshSemanticKeys GV_LAST_ATTR
#define MeshSemanticKey      GenericVariables
#define EQSTR(a,b) (a && ([a caseInsensitiveCompare:b] == NSOrderedSame))


//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingTriangleTag @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@interface IncomingPolygonIndex : NSObject {
@public
    int              _count;
    MeshSemanticKey  _semanticKey[kNumMeshSemanticKeys];
    int              _offsets[kNumMeshSemanticKeys];
    NSMutableArray * _sourceURL;
    unsigned short * _primitives;
    unsigned short * _vectorCounts;
    
    int              _numPrimitives;
    int              _nextInput;
    
    bool             _isActualTrianglesForReal;
    
    NSString *       _materialName;
}

@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@ IncomingVertexData  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

typedef struct _IncomingGeometryBuffer {
    float * data;
    int     stride;
    int     numFloats;
    int     numElements;
} IncomingGeometryBuffer;


@interface IncomingSourceTag : NSObject {
@public
    IncomingGeometryBuffer _bufferInfo;
    
    NSString *  _id;
    NSMutableDictionary *  _redirectTo;
}
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingMeshData @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@interface IncomingMeshData : NSObject {
@public
    NSString *             _geometryName;
    NSMutableDictionary *  _sources;        // vertex data here
    NSMutableArray *       _polygonTags;    // index data here
    
    IncomingSourceTag *   _tempIncomingSourceTag;
    
    bool _honorUVs;
}
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingSkinSource @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@interface IncomingSkinSource : NSObject {
@public
    NSString *   _id;
    int          _count;
    NSString *   _source;
    int          _accCount;
//  int          _strideAttr;
    NSArray *    _nameArray;
    GLKMatrix4 * _matrices;
    int          _numMatrices;
    float *      _weights; // <source>...<param name="WEIGHT" type="float"/>
    int          _numWeights;
    NSString *   _paramName;
    NSString *   _paramType;
}
@end

typedef enum _SkinSemanticKey {
    SSKJoint,
    SSKWeight,
    
    kNumSkinSemanticKeys
} SkinSemanticKey;

@interface IncomingWeights : NSObject { // <vertex_weights>....
@public
    int               _count;
    SkinSemanticKey   _semanticKey[kNumSkinSemanticKeys]; // N.B. these are NOT ordered
    int               _offsets[kNumSkinSemanticKeys];
    NSMutableArray *  _sources;
    unsigned short *  _vcounts;
    unsigned short *  _weights;
    unsigned int      _numVcounts;
    unsigned int      _numWeights;
    
    int _nextInput;
}
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingSkin @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@interface IncomingSkin  : NSObject {
@public
    NSMutableArray * _incomingSources;
    NSMutableDictionary * _jointDict;
    IncomingWeights  * _weights;
    NSString * _controllerId;
    NSString * _controllerName;
    NSString * _meshSource;
    GLKMatrix4 _bindShapeMatrix;
    
    IncomingSkinSource * _weightSource;
}
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingNodeTree @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

typedef enum _NodeCoordSpec {
    NCSLocation = 1,
    NCSRotationX = 1 << 1,
    NCSRotationY = 1 << 2,
    NCSRotationZ = 1 << 3,
    NCSScale = 1 << 4
} NodeCoordSpec;

@class IncomingNode;

@interface IncomingNode  : NSObject {
@public
    NSString * _id;
    NSString * _name;
    NSString * _sid;
    NSString * _type;
    
    MeshSceneNodeType _msnType;
    
    GLKMatrix4 _transform;
    
    NodeCoordSpec _coordSpec;
    GLKVector3 _location;
    GLKVector3 _rotationX;
    GLKVector3 _rotationY;
    GLKVector3 _rotationZ;
    GLKVector3 _scale;
    
    NSString * _skinName;
    NSString * _geometryName; // no skinning
    
    NSMutableDictionary * _children;
    NodeCoordSpec         _incomingSpec;
    
    __weak IncomingNode * _parent;
}
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingNodeTree @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@interface IncomingNodeTree : NSObject {
@public
    NSMutableDictionary * _tree;
    
    NSMutableArray * _nodeStack;
}
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingMaterial/Effect/Image @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

typedef enum EffectParamTags {
    et_NONE,
    et_ambient,
    et_diffuse,
    et_specular,
    et_emission,
    
    et_reflective,
    et_transparent, // opaque="RGB_ZERO"
    
    et_shininess,
    et_reflectivity,
    et_transparency,
} EffectParamTags;


@class IncomingEffect;

@interface IncomingMaterial : NSObject {
@public
    NSString * _name;
    NSString * _id;
    NSString * _effect;
    
    IncomingEffect * _instance;
}
@end

@interface IncomingNewParam : NSObject {
@public
    NSString * _id;
    NSString * _tag; // <surface, <sampler2d
    NSString * _contentTag; // <init_from, <source
    NSString * _content; // contents of <init_from>..</> or <source>..</>
}
@end

@interface IncomingEffect : NSObject {
@public
    NSString *      _id;
    NSString *      _type; // 'phong'
    EffectParamTags _incomingDataTag;
    
    MaterialColors _colors;
    float          _shininess;
    
    NSString * _textureName;
    NSString * _texCoordName;
    
    IncomingNewParam * _incomingNewParam;
    NSMutableDictionary * _newParams;
    
}
@end

@interface IncomingImage : NSObject {
@public
    NSString * _id;
    NSString * _name;
    NSString * _init_from;
}
@end

@class MeshAnimation;

@interface IncomingAnimation : NSObject {
@public
    MeshAnimation * _animation;
    NSString * _channelTarget;
    NSString * _paramType;
    NSString * _paramName;
    NSString * _id;
    NSString * _name;
    
    NSMutableDictionary * _sourceDict;
    NSMutableDictionary * _samplerDict;    
}
@end

@interface IncomingAnimationSource : NSObject {
    float *          _floats;
    unsigned int     _count;
    NSMutableArray * _names;
}

@end

typedef enum _ColladaTagState
{
    kColStateIntArray         = 1,
    kColStateFloatArray       = 1 << 1,
    kColStateStringArray      = 1 << 2,
    kColStateFloat            = 1 << 3,
    kColStateCaptureText      = 1 << 4,
    
    kColStateInAnimation      = 1 << 8,
    kColStateInMeshGeometry   = 1 << 9,
    kColStateMaterialLibrary  = 1 << 10,
    kColStateEffectLibrary    = 1 << 11,
    kColStateSkin             = 1 << 12,
    kColStateVisualScene      = 1 << 13,
    kColStateImageLibrary     = 1 << 14,
    kColStateSampler          = 1 << 15,
    
    kColStateImage            = 1 << 17,
    kColStateInSource         = 1 << 18,
    kColStateInVertices       = 1 << 19,
    kColStatePolyIndices      = 1 << 20,
    kColStateVertexWeights    = 1 << 21,
    kColStateJoint            = 1 << 22,
    kColStateInNode           = 1 << 23,
    kColStateUp               = 1 << 24,
    kColStateMaterialTag      = 1 << 25,
    kColStateEffectTag        = 1 << 26,
    kColStatePhong            = 1 << 27,
    kColStateLambert          = 1 << 28,
    
    
} ColladaTagState;


@interface ColladaParserImpl : NSObject<NSXMLParserDelegate>  {
    NSMutableDictionary * _animDict;
    NSMutableDictionary * _geometries;
    NSMutableDictionary * _skins;
    NSMutableDictionary * _nodes;
    NSMutableDictionary * _materials;
    NSMutableDictionary * _effects;
    NSMutableDictionary * _images;
    NSMutableDictionary * _materialBindings;    
}
@end

@interface ColladaParserImpl (Finalize)
-(MeshScene *)finalAssembly;
@end

@interface ColladaParserImpl (MemPool)
-(void *)malloc:(size_t)sz;
@end