//
//  main.m
//  aotkXML
//
//  Created by victor on 3/21/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MeshScene.h"
#import "ColladaParser.h"
#import "ColladaNames.h"
#import "Log.h"

#define CULL_NULL_ANIMATIONS 1

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

#define SET(f)      _state |= f
#define UNSET(f)    _state &= ~f
#define CHECK(f)    ((_state & f) == f)

#define EQSTR(a,b) (a && ([a caseInsensitiveCompare:b] == NSOrderedSame))

#define EQMAT4(a,b) ( memcmp(a.m,b.m,sizeof(a.m)) == 0 )


static float * parseFloats(NSString * str, int * numFloats)
{
    str = [str stringByTrimmingCharactersInSet:
           [NSCharacterSet whitespaceCharacterSet]];
    NSArray * burp = [str componentsSeparatedByString:@" "];
    unsigned long count = [burp count];
    float * p = malloc(sizeof(float)*count);
//   TGLog(LLShitsOnFire, @"malloc: %p",p);
    *numFloats = (int)count;
    float * buffer = p;
    for( NSString * f in burp )
        *p++ = [f floatValue];
    return buffer;
}

static unsigned short * parseUShorts(NSString * str, int * numUShorts)
{
    str = [str stringByTrimmingCharactersInSet:
           [NSCharacterSet whitespaceCharacterSet]];
    NSArray * burp = [str componentsSeparatedByString:@" "];
    unsigned long count = [burp count];
    unsigned short * p = malloc(sizeof(unsigned short)*count);
    *numUShorts = (int)count;
    unsigned short * buffer = p;
    for( NSString * f in burp )
        *p++ = (unsigned short)[f intValue];
    return buffer;
}

static NSArray * parseStringArray( NSString * str )
{
    str = [str stringByTrimmingCharactersInSet:
           [NSCharacterSet whitespaceCharacterSet]];
    return [str componentsSeparatedByString:@" "];
}

static int scanInt(NSString * str)
{
    NSScanner * scanner = [[NSScanner alloc] initWithString:str];
    int i;
    [scanner scanInt:&i];
    return i;
}


//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingAnimation @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@interface IncomingAnimation : NSObject {
@public
    MeshAnimation * _animation;
    NSString * _channelTarget;
    NSString * _paramType;
    NSString * _paramName;
}
@end
@implementation IncomingAnimation
- (id)init
{
    self = [super init];
    if (self) {
        _animation = [MeshAnimation new];
    }
    return self;
}

@end

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
@implementation IncomingPolygonIndex

- (id)init
{
    self = [super init];
    if (self) {
        _sourceURL = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc
{
    TGLog(LLObjLifetime, @"Releasing %@",self);
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
    NSString *  _redirectTo;
}
@end
@implementation IncomingSourceTag
- (void)dealloc
{
    TGLog(LLObjLifetime, @"Releasing %@",self);
}
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingMeshData @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@interface IncomingMeshData : NSObject {
@public
    NSString *             _geometryName;
    NSMutableDictionary *  _sources;        // vertex data here
    NSMutableArray *       _polygonTags;    // index data here
    
    IncomingSourceTag *   _tempIncomingSourceTag;
    

    // filled in at finalize
  //  MeshGeometry_OLD *         _meshGeometry;
}
@end
@implementation IncomingMeshData
- (id)init
{
    self = [super init];
    if (self) {
        _sources = [NSMutableDictionary new];
        _polygonTags = [NSMutableArray new];
    }
    return self;
}
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingSkinSource @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@interface IncomingSkinSource : NSObject {
@public
    NSString * _id;
    int        _count;
    NSString * _source;
    int        _accCount;
    int        _stride;
    NSArray *  _nameArray;
    float *    _data;
    int        _numFloats;
    NSString * _paramName;
    NSString * _paramType;
}
@end
@implementation IncomingSkinSource

@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingWeights  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

typedef enum _SkinSemanticKey {
    SSKJoint,
    SSKWeight,
    
    kNumSkinSemanticKeys
} SkinSemanticKey;

@interface IncomingWeights : NSObject {
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
@implementation IncomingWeights

- (id)init
{
    self = [super init];
    if (self) {
        _sources = [NSMutableArray new];
    }
    return self;
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
}
@end

@implementation IncomingSkin

- (id)init
{
    self = [super init];
    if (self) {
        _incomingSources = [NSMutableArray new];
        _jointDict = [NSMutableDictionary new];
    }
    return self;
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

@implementation IncomingNode

-(void)addChild:(IncomingNode *)child
{
    if( !_children )
        _children = [NSMutableDictionary new];
    _children[child->_id] = child;
}

@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingNodeTree @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@interface IncomingNodeTree : NSObject {
@public
    NSMutableDictionary * _tree;
    
    NSMutableArray * _nodeStack;
}
@end

@implementation IncomingNodeTree

- (id)init
{
    self = [super init];
    if (self) {
        _tree = [NSMutableDictionary new];
        _nodeStack = [NSMutableArray new];
    }
    return self;
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

static const char * effectParamTags[] = {
    "",
    // colors
    _kTag_ambient,
    _kTag_diffuse,
    _kTag_specular,
    _kTag_emission,
    // colors (unsupported)
    _kTag_reflective,
    _kTag_transparent, // opaque="RGB_ZERO">
    // floats
    _kTag_shininess,
    // floats (unsupported)
    _kTag_transparency,
    _kTag_reflectivity,
};

@class IncomingEffect;

@interface IncomingMaterial : NSObject {
@public
    NSString * _name;
    NSString * _id;
    NSString * _effect;
    
    IncomingEffect * _instance;
}
@end

@implementation IncomingMaterial
@end

@interface IncomingNewParam : NSObject {
    @public
    NSString * _id;
    NSString * _tag; // <surface, <sampler2d
    NSString * _contentTag; // <init_from, <source
    NSString * _content; // contents of <init_from>..</> or <source>..</>
}
@end

@implementation IncomingNewParam
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

@implementation IncomingEffect
-(void)addNewParam:(NSString *)name value:(id)value
{
    if( !_newParams )
        _newParams = [NSMutableDictionary new];
    _newParams[name] = value;
}
@end

@interface IncomingImage : NSObject {
@public
    NSString * _id;
    NSString * _name;
    NSString * _init_from;
}
@end
@implementation IncomingImage

@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  ColladaParser @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#pragma mark CollalaParserImpl

@interface ColladaParserImpl : NSObject<NSXMLParserDelegate> {

    id              _incoming;

    char            _up;
    
    ColladaTagState _state;
    
    NSMutableString * _floatString;
    float * _floatArray;
    int _floatArrayCount;
    
    NSMutableString * _ushortString;
    unsigned short * _ushortArray;
    int _ushortArrayCount;
    
    NSMutableString * _stringArrayString;

    NSString * _captureString;
    
    NSMutableDictionary * _animations;
    NSMutableDictionary * _geometries;
    NSMutableDictionary * _skins;
    NSMutableDictionary * _nodes;
    NSMutableDictionary * _materials;
    NSMutableDictionary * _effects;
    NSMutableDictionary * _images;
    
    NSMutableDictionary * _materialBindings;
}
@end

@implementation ColladaParserImpl

-(id)init
{
    self = [super init];
    if( self )
    {
        _animations = [NSMutableDictionary new];
        _geometries = [NSMutableDictionary new];
        _skins      = [NSMutableDictionary new];
        _nodes      = [NSMutableDictionary new];
        _materials  = [NSMutableDictionary new];
        _effects    = [NSMutableDictionary new];
        _materialBindings = [NSMutableDictionary new];
        _images = [NSMutableDictionary new];
        _up         = 'y';
    }
    return self;
}

-(void)dealloc
{
    TGLog(LLObjLifetime, @"%@ released", self);
}

-(void)handleAnimation:(NSString *)elementName
            attributes:(NSDictionary *)attributeDict
{
    IncomingAnimation * ia = _incoming;
    
    if( attributeDict )
    {
        if( EQSTR(elementName,kTag_float_array) )
        {
            _floatArrayCount = scanInt(attributeDict[kAttr_count]);
            SET(kColStateFloatArray);
            return;
        }
        
        if( EQSTR(elementName,kTag_param) )
        {
            ia->_paramName = attributeDict[kAttr_name];
            ia->_paramType = attributeDict[kAttr_type];
            return;
        }
        
        if( EQSTR(elementName,kTag_channel) )
        {
            ia->_channelTarget = attributeDict[kAttr_target];
        }
    }
    else
    {
        if( EQSTR(elementName,kTag_source) )
        {
            if( EQSTR(ia->_paramName,kValue_name_TIME) )
            {
                ia->_animation->_keyFrames = _floatArray;
                ia->_animation->_numFrames = _floatArrayCount;
                
                _floatArray = NULL;
                _floatArrayCount = 0;
            }
            else if( EQSTR(ia->_paramName,kValue_name_TRANSFORM) )
            {
                if( EQSTR(ia->_paramType,kValue_type_float4x4) )
                {
                    unsigned int numMatrices = _floatArrayCount / 16;
                    GLKMatrix4 * mats = (GLKMatrix4 *)_floatArray;
                    for( unsigned int i = 0; i < numMatrices; i++ )
                        mats[i] = GLKMatrix4Transpose(mats[i]);
                    ia->_animation->_transforms = mats;
                }
                _floatArray = NULL;
                _floatArrayCount = 0;
            }
        }
        
    }
}

-(void)assembleAnimation
{
    IncomingAnimation * ia = _incoming;
    _animations[ia->_channelTarget] = ia->_animation;
    _incoming = nil;
    UNSET(kColStateInAnimation);
}

-(void)handleMeshGeometry:(NSString *)elementName
               attributes:(NSDictionary *)attributeDict
{
    IncomingMeshData * meshData = _incoming;
    
    if( attributeDict )
    {
        bool bIsSource         = EQSTR(elementName,kTag_source);
        bool bIsVertexRedirect = EQSTR(elementName,kTag_vertices);
        if(  bIsSource || bIsVertexRedirect )
        {
            IncomingSourceTag *ims = [IncomingSourceTag new];
            ims->_id = attributeDict[kAttr_id];
            
            meshData->_sources[ims->_id] = ims;
            
            meshData->_tempIncomingSourceTag = ims;
            
            if( bIsSource )
                SET(kColStateInSource);
            else
                SET(kColStateInVertices);
            return;
        }

        bool isTriangles = EQSTR(elementName, kTag_triangles);
        bool isPolylist  = EQSTR(elementName, kTag_polylist);
        if(  isTriangles || isPolylist  )
        {
            IncomingPolygonIndex * polyTag = [[IncomingPolygonIndex alloc] init];
            polyTag->_isActualTrianglesForReal = isTriangles;
            polyTag->_count = scanInt(attributeDict[kAttr_count]);
            polyTag->_materialName = attributeDict[kAttr_material];
            
            [meshData->_polygonTags addObject:polyTag];
            
            SET(kColStatePolyIndices);
            return;
        }
        
        if( CHECK(kColStateInSource) )
        {
            if( EQSTR(elementName, kTag_float_array) )
            {
                SET(kColStateFloatArray);
                return;
            }
            
            if( EQSTR(elementName,kTag_accessor) )
            {
                IncomingSourceTag * ims = meshData->_tempIncomingSourceTag;
                ims->_bufferInfo.numElements = scanInt(attributeDict[kAttr_count]);
                ims->_bufferInfo.stride      = scanInt(attributeDict[kAttr_stride]);
                return;
            }
        }
        
        if( CHECK(kColStateInVertices) )
        {
            if( EQSTR(elementName,kTag_input) )
            {
                IncomingSourceTag * ims = meshData->_tempIncomingSourceTag;
                ims->_redirectTo = [(NSString *)attributeDict[kAttr_source] substringFromIndex:1];
            }
            
            return;
        }
        
        if( CHECK(kColStatePolyIndices) )
        {
            if( EQSTR(elementName, kTag_input) )
            {
                IncomingPolygonIndex * polyIndexTag = [meshData->_polygonTags lastObject];
                int idx = polyIndexTag->_nextInput;
                
                // 1. Get semantic
                //
                MeshSemanticKey sem;
                NSString * semantic = attributeDict[kAttr_semantic];
                if( EQSTR(semantic, kValue_semantic_VERTEX) )
                    sem = MSKPosition;
                else if( EQSTR(semantic, kValue_semantic_NORMAL) )
                    sem = MSKNormal;
                else if( EQSTR(semantic, kValue_semantic_TEXCOORD) )
                    sem = MSKUV;
                else if( EQSTR(semantic, kValue_semantic_COLOR) )
                    sem = MSKColor;
                else {
                    NSLog(@"Unknown mesh semantic type: %@",semantic);
                    exit(-1);
                }
                polyIndexTag->_semanticKey[idx] = sem;
                
                // 2. get offset
                //
                polyIndexTag->_offsets[idx] = scanInt(attributeDict[kAttr_offset]);
                
                // 3. get source (what this is referring to)
                //
                polyIndexTag->_sourceURL[idx] = [(NSString *)attributeDict[kAttr_source] substringFromIndex:1];
                
                polyIndexTag->_nextInput++;
                return;
            }
            
            if( EQSTR(elementName, kTag_p) || EQSTR(elementName, kTag_vcount) )
            {
                SET(kColStateIntArray);
                return;
            }
        }
    }
    else
    {
        if( CHECK(kColStateInVertices) )
        {
            IncomingSourceTag * ivd = meshData->_tempIncomingSourceTag;
            meshData->_sources[ivd->_id] = ivd;
            meshData->_tempIncomingSourceTag = nil;
            UNSET(kColStateInVertices);
            return;
        }
        
        if( CHECK(kColStatePolyIndices) )
        {
            if( EQSTR(elementName, kTag_p) )
            {
                IncomingPolygonIndex * polyIndexTag = [meshData->_polygonTags lastObject];
                polyIndexTag->_primitives = _ushortArray;
                polyIndexTag->_numPrimitives = _ushortArrayCount;
                _ushortArrayCount = 0;
                _ushortArray = NULL;
                return;
            }
            
            if( EQSTR(elementName, kTag_vcount) )
            {
                IncomingPolygonIndex * itt = [meshData->_polygonTags lastObject];
                itt->_vectorCounts = _ushortArray;
                _ushortArrayCount = 0;
                _ushortArray = NULL;
                return;
            }
            
            if( EQSTR(elementName, kTag_triangles) || EQSTR(elementName, kTag_polylist) )
            {
                UNSET(kColStatePolyIndices);
                return;
            }
        }

        if( CHECK(kColStateInSource) )
        {
            if( EQSTR(elementName, kTag_source) )
            {
                IncomingSourceTag * ivd = meshData->_tempIncomingSourceTag;
                ivd->_bufferInfo.numFloats = _floatArrayCount;
                ivd->_bufferInfo.data = _floatArray;
                _floatArray = NULL;
                _floatArrayCount = 0;
                
                meshData->_tempIncomingSourceTag = nil;
                UNSET(kColStateInSource);
            }
        }
    }
}

-(void)assembleGeometry
{
    IncomingMeshData * meshData = _incoming;
    _geometries[ meshData->_geometryName ] = _incoming;
    UNSET(kColStateInMeshGeometry);
    _incoming = nil;
    
}
-(void)handleSkin:(NSString *)elementName
       attributes:(NSDictionary *)attributeDict
{
    IncomingSkin * iskin = _incoming;
    
    if( attributeDict )
    {
        if( CHECK(kColStateInSource) )
        {
            if( EQSTR(elementName, kTag_Name_array) )
            {
                SET(kColStateStringArray);
                return;
            }
            
            if( EQSTR(elementName, kTag_float_array) )
            {
                SET(kColStateFloatArray);
                return;
            }
            
            if( EQSTR(elementName, kTag_accessor) )
            {
                IncomingSkinSource * iss = [iskin->_incomingSources lastObject];
                iss->_accCount = scanInt(attributeDict[kAttr_count]);
                iss->_stride = scanInt(attributeDict[kAttr_stride]);
                return;
            }
            
            if( EQSTR(elementName, kTag_param) )
            {
                IncomingSkinSource * iss = [iskin->_incomingSources lastObject];
                iss->_paramName = attributeDict[kAttr_name];
                iss->_paramType = attributeDict[kAttr_type];
                return;                
            }
        }
        
        
        if( CHECK(kColStateVertexWeights) )
        {
            if( EQSTR(elementName, kTag_v) )
            {
                SET(kColStateIntArray);
                return;
            }
            
            if( EQSTR(elementName, kTag_vcount) )
            {
                SET(kColStateIntArray);
                return;
            }
            
            if( EQSTR(elementName, kTag_input) )
            {
                IncomingWeights * iw = iskin->_weights;
                int idx = iw->_nextInput;
                
                // 1. Get semantic
                //
                SkinSemanticKey  ssk;
                NSString * semantic = attributeDict[kAttr_semantic];
                if( EQSTR(semantic, kValue_semantic_JOINT) )
                    ssk = SSKJoint;
                else if( EQSTR(semantic, kValue_semantic_WEIGHT) )
                    ssk = SSKWeight;
                else {
                    NSLog(@"Unknown skin semantic type: %@",semantic);
                    exit(-1);
                }
                iw->_semanticKey[idx] = ssk;
                
                // 2. get offset
                //
                iw->_offsets[idx] = scanInt(attributeDict[kAttr_offset]);
                
                // 3. get source (what this is referring to)
                //
                iw->_sources[idx] = [(NSString *)attributeDict[kAttr_source] substringFromIndex:1];
                
                iw->_nextInput++;
                return;
            }
        }
        
        if( EQSTR(elementName, kTag_vertex_weights) )
        {
            iskin->_weights = [IncomingWeights new];
            iskin->_weights->_count = scanInt(attributeDict[kAttr_count]);
            SET(kColStateVertexWeights);
            return;            
        }
        
        if( EQSTR(elementName, kTag_skin) )
        {
            iskin->_meshSource = [attributeDict[kAttr_source] substringFromIndex:1];
            return;
        }
        
        if( EQSTR(elementName, kTag_bind_shape_matrix) )
        {
            SET(kColStateFloatArray);
            return;
        }
        
        if( EQSTR(elementName, kTag_source) )
        {
            IncomingSkinSource * iss = [IncomingSkinSource new];
            iss->_id = attributeDict[kAttr_id];
            [iskin->_incomingSources addObject:iss];
            SET(kColStateInSource);
            return;
        }
    }
    else
    {
        if( CHECK(kColStateInSource) )
        {
            if( EQSTR(elementName, kTag_source) )
            {
                IncomingSkinSource * iss = [iskin->_incomingSources lastObject];
                if( _stringArrayString )
                {
                    iss->_nameArray = parseStringArray(_stringArrayString);
                    _stringArrayString = nil;
                    UNSET(kColStateStringArray);
                }
                if( _floatArray )
                {
                    iss->_data = _floatArray;
                    iss->_numFloats = _floatArrayCount;
                    _floatArray = NULL;
                    _floatArrayCount = 0;
                }
                UNSET(kColStateInSource);
                return;
            }
        }
        
        if( CHECK(kColStateVertexWeights) )
        {
            if( EQSTR(elementName, kTag_vcount) )
            {
                iskin->_weights->_vcounts = _ushortArray;
                iskin->_weights->_numVcounts = _ushortArrayCount;
                _ushortArray = NULL;
                _ushortArrayCount = 0;
                return;
            }
            
            if( EQSTR(elementName, kTag_v) )
            {
                iskin->_weights->_weights = _ushortArray;
                iskin->_weights->_numWeights = _ushortArrayCount;
                _ushortArray = NULL;
                _ushortArrayCount = 0;
                return;
            }
            
            if( EQSTR(elementName, kTag_vertex_weights) )
            {
                UNSET(kColStateVertexWeights);
                return;
            }
        }
        
        if( EQSTR(elementName, kTag_bind_shape_matrix) )
        {
            iskin->_bindShapeMatrix = GLKMatrix4MakeWithArrayAndTranspose(_floatArray);
            _floatArray = NULL;
            _floatArrayCount = 0;
            return;
        }
        
    }
    
}

-(void)assembleSkin
{
    IncomingSkin * iskin = _incoming;
    _skins[ iskin->_controllerId ] = iskin;
    _incoming = nil;
    UNSET(kColStateSkin);
}

-(void)handleScene:(NSString *)elementName
       attributes:(NSDictionary *)attributeDict
{
    IncomingNodeTree * incnt = _incoming;
    
    if( attributeDict )
    {
        if( CHECK(kColStateInNode) )
        {
            if( EQSTR(elementName, kTag_matrix) )
            {
                SET(kColStateFloatArray);
                return;
            }
            
            if( EQSTR(elementName, kTag_translate) )
            {
                SET(kColStateFloatArray);
                return;
            }
            
            if( EQSTR(elementName, kTag_scale) )
            {
                SET(kColStateFloatArray);
                return;
            }
            
            if( EQSTR(elementName, kTag_rotate) )
            {
                SET(kColStateFloatArray);
                NSString * sid = attributeDict[kAttr_sid];
                IncomingNode * inode = [incnt->_nodeStack lastObject];
                if( EQSTR(sid, kValue_sid_rotationX) )
                    inode->_incomingSpec = NCSRotationX;
                else if( EQSTR(sid, kValue_sid_rotationY) )
                    inode->_incomingSpec = NCSRotationY;
                else
                    inode->_incomingSpec = NCSRotationZ;
                return;                    
            }
            
            if( EQSTR(elementName, kTag_skeleton) )
            {
                IncomingNode * inode = [incnt->_nodeStack lastObject];
                inode->_msnType = MSNT_SkinnedMesh;
                
                // we don't really need the "skeleton" name here
                //SET(kColStateCaptureText);
                return;
            }
            
            if( EQSTR(elementName, kTag_instance_controller) )
            {
                IncomingNode * inode = [incnt->_nodeStack lastObject];
                inode->_skinName = [(NSString *)attributeDict[kAttr_url] substringFromIndex:1];
                inode->_msnType = MSNT_SkinnedMesh;
                return;
            }
            
            if( EQSTR(elementName, kTag_instance_geometry) )
            {
                IncomingNode * inode = [incnt->_nodeStack lastObject];
                inode->_geometryName = [(NSString *)attributeDict[kAttr_url] substringFromIndex:1];
                inode->_msnType = MSNT_Mesh;
                return;
            }
            
            if( EQSTR(elementName, kTag_instance_camera) )
            {
                IncomingNode * inode = [incnt->_nodeStack lastObject];
                inode->_msnType = MSNT_Camera;
                return;
            }
            
            if( EQSTR(elementName, kTag_instance_light) )
            {
                IncomingNode * inode = [incnt->_nodeStack lastObject];
                inode->_msnType = MSNT_Light;
                return;
            }
            
            if( EQSTR(elementName, kTag_instance_material) )
            {
//                <instance_material symbol="Shape02SG" target="#phong2"/>
                _materialBindings[ attributeDict[kAttr_symbol] ] = [attributeDict[kAttr_target] substringFromIndex:1];
            }
        }
        
        if( EQSTR(elementName, kTag_node) )
        {
            IncomingNode * inode = [IncomingNode new];
            inode->_sid  = attributeDict[kAttr_sid];
            inode->_name = attributeDict[kAttr_name];
            inode->_id   = attributeDict[kAttr_id];
            inode->_type = attributeDict[kAttr_type];
            
            IncomingNode * parent = [incnt->_nodeStack lastObject];
            if( parent )
                [parent addChild:inode];
            else
                incnt->_tree[inode->_id] = inode;
            [incnt->_nodeStack addObject:inode];
            
            inode->_parent = parent;
            if( EQSTR(inode->_type,@"JOINT") )
            {
                inode->_msnType = MSNT_Armature;
            }
            SET(kColStateInNode);
        }
    }
    else
    {
        if( CHECK(kColStateInNode) )
        {
            if( EQSTR(elementName, kTag_matrix) )
            {
                IncomingNode * inode = [incnt->_nodeStack lastObject];
                inode->_transform = GLKMatrix4MakeWithArrayAndTranspose(_floatArray);
                _floatArray = NULL;
                _floatArrayCount = 0;
                return;
            }
            
            if( EQSTR(elementName, kTag_translate) )
            {
                IncomingNode * inode = [incnt->_nodeStack lastObject];
                inode->_coordSpec |= NCSLocation;
                inode->_location = *(GLKVector3 *)_floatArray;
                _floatArray = NULL;
                _floatArrayCount = 0;
                return;
            }

            if( EQSTR(elementName, kTag_scale) )
            {
                IncomingNode * inode = [incnt->_nodeStack lastObject];
                inode->_coordSpec |= NCSScale;
                inode->_scale = *(GLKVector3 *)_floatArray;
                _floatArray = NULL;
                _floatArrayCount = 0;
                return;
            }

            if( EQSTR(elementName, kTag_rotate) )
            {
                IncomingNode * inode = [incnt->_nodeStack lastObject];
                if( inode->_incomingSpec == NCSRotationX )
                    inode->_rotationX = *(GLKVector3 *)_floatArray;
                else if( inode->_incomingSpec == NCSRotationY )
                    inode->_rotationY = *(GLKVector3 *)_floatArray;
                else
                    inode->_rotationZ = *(GLKVector3 *)_floatArray;
                inode->_coordSpec |= inode->_incomingSpec;
                inode->_incomingSpec = 0;
                _floatArray = NULL;
                _floatArrayCount = 0;
                return;
            }
            
            if( EQSTR(elementName, kTag_node) )
            {
                [incnt->_nodeStack removeLastObject];
                if( ![incnt->_nodeStack count] )
                {
                    UNSET(kColStateInNode);
                }
            }
            
        }
        
    }
}

-(void)assembleScene
{
    IncomingNodeTree * incnt = _incoming;
    _nodes = incnt->_tree;
    _incoming = nil;
    UNSET(kColStateVisualScene);
}


-(void)handleMaterials:(NSString *)elementName
            attributes:(NSDictionary *)attributeDict
{
    if( attributeDict )
    {
        if( EQSTR(elementName, kTag_material) )
        {
            IncomingMaterial * im = [[IncomingMaterial alloc] init];
            im->_id = attributeDict[kAttr_id];
            im->_name = attributeDict[kAttr_name];
            _materials[im->_id] = im;
            _incoming = im;
            SET(kColStateMaterialTag);
        }
        
        if( CHECK(kColStateMaterialTag) )
        {
            if( EQSTR(elementName, kTag_instance_effect) )
            {
                IncomingMaterial * im = _incoming;
                im->_effect = [(NSString *)attributeDict[kAttr_url] substringFromIndex:1];
            }
        }
    }
    else
    {
        if( CHECK(kColStateMaterialTag) )
        {
            if( EQSTR(elementName, kTag_material) )
            {
                _incoming = nil;
                UNSET(kColStateMaterialTag);
            }
        }
    }
}

-(void)handleEffects:(NSString *)elementName
          attributes:(NSDictionary *)attributeDict
{
    if( attributeDict )
    {
        if( CHECK(kColStateEffectTag) )
        {
            IncomingEffect * ie = _incoming;
            
            if( ie->_incomingNewParam )
            {
                if( EQSTR(elementName, kTag_surface) || EQSTR(elementName, kTag_sampler2D) )
                {
                    ie->_incomingNewParam->_tag = elementName;
                    return;
                }
                
                if( EQSTR(elementName, kTag_init_from) || EQSTR(elementName, kTag_source) )
                {
                    ie->_incomingNewParam->_contentTag = elementName;
                    SET(kColStateCaptureText);
                    return;
                }
            }
            
            if( EQSTR(elementName, kTag_texture) )
            {
                ie->_textureName = attributeDict[kAttr_texture];
                ie->_texCoordName = attributeDict[kAttr_texcoord];
                return;
            }
            if( EQSTR(elementName, kTag_newparam) )
            {
                ie->_incomingNewParam = [IncomingNewParam new];
                ie->_incomingNewParam->_id = attributeDict[kAttr_sid];
                return;
            }
            
            if( EQSTR(elementName, kTag_color) )
            {
                SET(kColStateFloatArray);
                return;
            }
            
            if( EQSTR(elementName, kTag_float) )
            {
                SET(kColStateFloat);
                return;
            }
            
            if( EQSTR(elementName, kTag_phong) )
            {
                ie->_type = elementName;
                return;
            }
            
            if( EQSTR(elementName, kTag_lambert) )
            {
                ie->_type = elementName;
                return;
                
            }
            for( int i = 0; i < sizeof(effectParamTags)/sizeof(effectParamTags[0]); i++ )
            {
                if( EQSTR(elementName, @(effectParamTags[i])) )
                {
                    ie->_incomingDataTag = i;
                    return;
                }
            }
            
        }
        
        if( EQSTR(elementName, kTag_effect) )
        {
            IncomingEffect * ie = [[IncomingEffect alloc] init];
            ie->_id = attributeDict[kAttr_id];
            _effects[ie->_id] = ie;
            _incoming = ie;
            SET(kColStateEffectTag);
            return;
        }
    }
    else
    {
        if( CHECK(kColStateEffectTag) )
        {
            IncomingEffect * ie = _incoming;
            
            if( ie->_incomingNewParam )
            {
                if( EQSTR(elementName, kTag_init_from) || EQSTR(elementName, kTag_source) )
                {
                    ie->_incomingNewParam->_content = _captureString;
                    _captureString = nil;
                    return;
                }
                
                if( EQSTR(elementName, kTag_newparam) )
                {
                    [ie addNewParam:ie->_incomingNewParam->_id value:ie->_incomingNewParam];
                    ie->_incomingNewParam = nil;
                }
                return;
            }
            
            if( EQSTR(elementName, kTag_color) )
            {
                GLKVector4 color = *(GLKVector4 *)_floatArray;
                switch (ie->_incomingDataTag) {
                    case et_ambient:
                        ie->_colors.ambient = color;
                        break;
                    case et_diffuse:
                        ie->_colors.diffuse = color;
                        break;
                    case et_emission:
                        ie->_colors.emission = color;
                        break;
                    case et_specular:
                        ie->_colors.specular = color;
                        break;
                    default:
                        break;
                }
                ie->_incomingDataTag = et_NONE;
                _floatArray = NULL;
                _floatArrayCount = 0;
                return;
            }
            
            if( EQSTR(elementName, kTag_float) )
            {
                float val = [_floatString floatValue];
                switch (ie->_incomingDataTag) {
                    case et_shininess:
                        ie->_shininess = val;
                        break;                        
                    default:
                        break;
                }
                ie->_incomingDataTag = et_NONE;
                _floatString = NULL;
                return;
            }
            
            if( EQSTR(elementName, kTag_effect) )
            {
                _incoming = nil;
                UNSET(kColStateEffectTag);
                return;
            }
        }
        
    }
}

-(void)handleImages:(NSString *)elementName
          attributes:(NSDictionary *)attributeDict
{
    if( attributeDict )
    {
        if( CHECK(kColStateImage) )
        {
            if( EQSTR(elementName, kTag_init_from) )
            {
                SET(kColStateCaptureText);
                return;
            }
        }
        
        if( EQSTR(elementName, kTag_image) )
        {
            IncomingImage * ii = [IncomingImage new];
            ii->_id = attributeDict[kAttr_id];
            ii->_name = attributeDict[kAttr_name];
            _images[ii->_id] = ii;
            _incoming = ii;
            SET(kColStateImage);
            return;
        }
    }
    else
    {
        if( CHECK(kColStateImage) )
        {
            if( EQSTR(elementName, kTag_init_from) )
            {
                IncomingImage * ii = _incoming;
                ii->_init_from = _captureString;
                _captureString = nil;
            }
        }
        
        if( EQSTR(elementName, kTag_image) )
        {
            UNSET(kColStateImage);
            _incoming = nil;
            return;
        }
    }
}

-(void)    parser:(NSXMLParser *)parser
  didStartElement:(NSString *)elementName
     namespaceURI:(NSString *)namespaceURI
    qualifiedName:(NSString *)qualifiedName
       attributes:(NSDictionary *)attributeDict
{
    if( CHECK(kColStateInAnimation) )
    {
        [self handleAnimation:elementName attributes:attributeDict];
        return;
    }
    
    if( CHECK(kColStateInMeshGeometry) )
    {
        [self handleMeshGeometry:elementName attributes:attributeDict];
        return;
    }
    
    if( CHECK(kColStateSkin) )
    {
        [self handleSkin:elementName attributes:attributeDict];
        return;
    }
    
    if( CHECK(kColStateVisualScene) )
    {
        [self handleScene:elementName attributes:attributeDict];
        return;
    }
    
    if( CHECK(kColStateMaterialLibrary) )
    {
        [self handleMaterials:elementName attributes:attributeDict];
        return;
    }
    
    if( CHECK(kColStateEffectLibrary) )
    {
        [self handleEffects:elementName attributes:attributeDict];
        return;
    }
    
    if( CHECK(kColStateImageLibrary) )
    {
        [self handleImages:elementName attributes:attributeDict];
        return;
    }
    
    if( EQSTR(elementName, kTag_controller) )
    {
        IncomingSkin * iskin = [IncomingSkin new];
        iskin->_controllerId = attributeDict[kAttr_id];
        iskin->_controllerName = attributeDict[kAttr_name];
        _incoming = iskin;
        SET(kColStateSkin);
        return;
    }
    
    if( EQSTR(elementName,kTag_animation) )
    {
        _incoming = [IncomingAnimation new];
        SET(kColStateInAnimation);
        return;
    }
    
    if( EQSTR(elementName,kTag_geometry) )
    {
        IncomingMeshData * imd = [IncomingMeshData new];
        _incoming = imd;
        imd->_geometryName = attributeDict[kAttr_id];
        SET(kColStateInMeshGeometry);
        return;
    }
    
    if( EQSTR(elementName, kTag_visual_scene) )
    {
        _incoming = [IncomingNodeTree new];
        SET(kColStateVisualScene);
        return;
    }
    
    if( EQSTR(elementName, kTag_up_axis) )
    {
        SET(kColStateUp);
        SET(kColStateCaptureText);
        return;
    }
    
    if( EQSTR(elementName, kTag_library_materials) )
    {
        SET(kColStateMaterialLibrary);
        return;
    }
    
    if( EQSTR(elementName, kTag_library_effects) )
    {
        SET(kColStateEffectLibrary);
        return;
    }
    
    if( EQSTR(elementName, kTag_library_images) )
    {
        SET(kColStateImageLibrary);
        return;
    }
}

-(void)  parser:(NSXMLParser *)parser
foundCharacters:(NSString *)string
{
    if( CHECK(kColStateFloatArray) )
    {
        if( _floatString )
            [_floatString appendString:string];
        else
            _floatString = [NSMutableString stringWithString:string];
        return;
    }
    
    if( CHECK(kColStateFloat) )
    {
        _floatString = [NSMutableString stringWithString:string];
        UNSET(kColStateFloat);
        return;
    }
    
    if( CHECK(kColStateIntArray) )
    {
        if( _ushortString )
           [_ushortString appendString:string];
        else
            _ushortString = [NSMutableString stringWithString:string];
        return;
    }
    
    if( CHECK(kColStateStringArray) )
    {
        if( _stringArrayString )
           [_stringArrayString appendString:string];
        else
            _stringArrayString = [NSMutableString stringWithString:string];
        return;
    }
    
    if( CHECK(kColStateCaptureText) )
    {
        _captureString = string;
        UNSET(kColStateCaptureText);
    }
}

- (void)   parser:(NSXMLParser *)parser
    didEndElement:(NSString *)elementName
     namespaceURI:(NSString *)namespaceURI
    qualifiedName:(NSString *)qName
{

    if( CHECK(kColStateStringArray) )
    {
        UNSET(kColStateStringArray);
        if( EQSTR(elementName, kTag_Name_array) )
            return;
    }
    
    if( CHECK(kColStateFloatArray) )
    {
        _floatArray = parseFloats(_floatString, &_floatArrayCount);
        _floatString = nil;
        UNSET(kColStateFloatArray);
        
        if( EQSTR(elementName,kTag_float_array) )
            return;
    }
    
    if( CHECK(kColStateIntArray) )
    {
        _ushortArray = parseUShorts(_ushortString, &_ushortArrayCount);
        _ushortString = nil;
        UNSET(kColStateIntArray);
        // return;
    }
    
    if( CHECK(kColStateSkin) )
    {
        if( EQSTR(elementName, kTag_controller) )
        {
            [self assembleSkin];
            UNSET(kColStateSkin);
            return;
        }
        
        [self handleSkin:elementName attributes:nil];
        return;
    }
    
    if( CHECK(kColStateInAnimation) )
    {
        if( EQSTR(elementName,kTag_animation) )
        {
            [self assembleAnimation];
            return;
        }
        
        [self handleAnimation:elementName attributes:nil];
        return;
    }
    
    if( CHECK(kColStateInMeshGeometry) )
    {
        if( EQSTR(elementName,kTag_geometry) )
        {
            [self assembleGeometry];
            return;
        }
        
        [self handleMeshGeometry:elementName attributes:nil];
        return;
    }
    
    if( CHECK(kColStateVisualScene) )
    {
        if( EQSTR(elementName, kTag_visual_scene) )
        {
            [self assembleScene];
            return;
        }
        
        [self handleScene:elementName attributes:nil];
        return;
    }
    
    if( CHECK(kColStateMaterialLibrary) )
    {
        if( EQSTR(elementName, kTag_library_materials) )
        {
            UNSET(kColStateMaterialLibrary);
            return;
        }
        
        [self handleMaterials:elementName attributes:nil];
        return;
    }

    if( CHECK(kColStateEffectLibrary) )
    {
        if( EQSTR(elementName, kTag_library_effects) )
        {
            UNSET(kColStateEffectLibrary);
            return;
        }
        
        [self handleEffects:elementName attributes:nil];
        return;
    }
    
    if( CHECK(kColStateImageLibrary) )
    {
        if( EQSTR(elementName, kTag_library_images) )
        {
            UNSET(kColStateImageLibrary);
            return;
        }
        
        [self handleImages:elementName attributes:nil];
        return;
    }
    
    if( CHECK(kColStateUp) )
    {
        if( EQSTR(_captureString, @"Z_UP") )
            _up = 'z';
        UNSET(kColStateUp);
    }

}

-(void)turnUp:(IncomingGeometryBuffer *)bufferInfo
{
    TGLog(LLShitsOnFire, @"Yea, unfortunately this code doesn't deal with anything but 'Y UP' colladas");
    exit(-1);
    
#if 0
    /*
        This is broken because we have to turn
        every single matrix too.
     */
     
    float * buffer = bufferInfo->data;
    for( int i = 0; i < bufferInfo->numFloats; i += 3 )
    {
        float y = buffer[i+1];
        buffer[i+1] = buffer[i+2];
        buffer[i+2] = y;
    }
#endif
    
}

-(bool)isTriangulated:(IncomingPolygonIndex *)polyIndexTag
{
    bool allThrees = true;
    
    if( !polyIndexTag->_isActualTrianglesForReal )
    {
        unsigned short *vectorCounts = polyIndexTag->_vectorCounts;
        if( vectorCounts )
        {
            for( unsigned int vc = 0; vc < polyIndexTag->_count; vc++ )
            {
                if( vectorCounts[vc] != 3 )
                {
                    allThrees = false;
                    break;
                }
            }
        }
    }
    
    return allThrees;
}

-(NSArray *)buildOpenGlBuffer:(IncomingMeshData *)imd
                    skin:(MeshSkinning *)skin
{
    NSMutableArray * geometries = [NSMutableArray new];
    
    float * flattenedJointWeightIndex = NULL;
    int numInfluencingJoints = 0;
    
    // A mesh in the Collada file can have several <triangle*>
    // tags - each representing a shape, typically with a
    // unique texture/material that are all draw from the
    // same vertext <source>
    
    // *there might also be <polylist> tags but this function
    // assumes the data has been triangulated at some point
    
    // The skinning information is shared between all shapes
    // so we massage it before digging into the <triangle>s
    if( skin )
    {
        // actually this is the number of POTENTIALLY influencing joints
        numInfluencingJoints = [skin->_influencingJoints count];
        
        // we need random access to the weight/joint information to
        // access it via the vertex index in the <triangle><p> we are
        // parsing below. The native format is packed such that non-
        // influencing joints do not appear. We will unpack to fixed
        // length fields (len:=number of possibly influencing joints)
        // and pad with 0 for irrelevant joints
        size_t sz = sizeof(float) * skin->_numInfluencingJointCounts * numInfluencingJoints;
        flattenedJointWeightIndex = malloc( sz );
        memset(flattenedJointWeightIndex,0,sz);
        float * p = flattenedJointWeightIndex;
        unsigned int currPos = 0;
        for( int i = 0; i < skin->_numInfluencingJointCounts; i++ )
        {
            // this is the actual number of joints applied to this vertex
            int numberOfJointsApplied = skin->_influencingJointCounts[i];
            unsigned int jointIndex;
            unsigned int weightIndex;
            for( int j = 0; j < numberOfJointsApplied; j++ )
            {
                jointIndex  = skin->_packedWeightIndices[ currPos + skin->_jointWOffset];
                weightIndex = skin->_packedWeightIndices[ currPos + skin->_weightFOffset];
                
                currPos += 2;
                
                p[jointIndex] = skin->_weights[weightIndex];
            }
            
            p += numInfluencingJoints;
        }
        
        
        free(skin->_influencingJointCounts);
        skin->_influencingJointCounts = NULL;
        free(skin->_packedWeightIndices);
        skin->_packedWeightIndices = NULL;
    }
    
    for( IncomingPolygonIndex * ipi in imd->_polygonTags)
    {
        IncomingSourceTag * isourceTags[kNumMeshSemanticKeys];
        memset(isourceTags, 0, sizeof(isourceTags));
        
        unsigned int primitivesOffset[kNumMeshSemanticKeys];
        unsigned int numVertices = ipi->_count * 3;
        unsigned int primitiveStride = 0;
        unsigned int numFloats = 0;
        
        for( int i = 0; i < ipi->_nextInput; i++ )
        {
            // dig out the relevant source tags
            NSString * srcName = ipi->_sourceURL[i];
            IncomingSourceTag * ist = imd->_sources[srcName];
            if( ist->_redirectTo )
                ist = imd->_sources[ist->_redirectTo];
            MeshSemanticKey key = ipi->_semanticKey[i];
            isourceTags[ key ] = ist;
            
            // calculate stride
            primitivesOffset[ key ] = ipi->_offsets[i];
            int thisOffset = primitivesOffset[key] + 1;
            if( thisOffset > primitiveStride )
                primitiveStride = thisOffset;
            
            // calculate num floats of target buffer
            numFloats += numVertices * ist->_bufferInfo.stride;
        }
        
        if( skin )
        {
            // 1 weight per vertext per joint
            numFloats += numInfluencingJoints * numVertices;
            /*
            // yea, it's a litle buried here but it's definitely
            // the most convient place to apply the BindShapeMatrix:
            IncomingSourceTag * ist = isourceTags[ MSKPosition ];
            GLKVector3 * vectors = (GLKVector3 *)ist->_bufferInfo.data;
            for( int v = 0; v < ist->_bufferInfo.numElements; v++ )
            {
                vectors[v] = GLKMatrix4MultiplyVector3(skin->_bindShapeMatrix, vectors[v]);
            }
             */
        }
        
        float * openGLBuffer = malloc( numFloats * sizeof(float) );
        float * p  = openGLBuffer;
        unsigned short int * primitives = ipi->_primitives;
        unsigned int index;
        unsigned int elementStride;
        float * source;
        
        for( int i = 0; i < numVertices; i++ )
        {
            for( int key = 0; key < kNumMeshSemanticKeys; key++ )
            {
                IncomingSourceTag * ist = isourceTags[key];
                if( !ist )
                    continue;
                
                index = primitives[ primitivesOffset[ key ] ];
                elementStride = ist->_bufferInfo.stride;
                source = ist->_bufferInfo.data + (index * elementStride);
                for( int stride = 0; stride < elementStride; stride++ )
                    *p++ = *source++;
            }
            if( skin )
            {
                index = primitives[ primitivesOffset[ MSKPosition ] ];
                float * weights = flattenedJointWeightIndex + (index * numInfluencingJoints);
                for( int w = 0; w < numInfluencingJoints; w++ )
                    *p++ = *weights++;
            }
            primitives += primitiveStride;
        }

        MeshGeometry * mg = [MeshGeometry new];
        mg->_name         = imd->_geometryName;
        mg->_materialName = ipi->_materialName;
        mg->_numVertices  = numVertices;
        mg->_buffer       = openGLBuffer;
        
        int strideCount = 0;
        for( int key = 0; key < kNumMeshSemanticKeys; key++ )
        {
            IncomingSourceTag * ist = isourceTags[key];
            if( !ist )
                continue;
            
            VertexStride * vs = &mg->_strides[ strideCount ];
            vs->glType = GL_FLOAT;
            vs->numSize = sizeof(float);
            vs->numbersPerElement = ist->_bufferInfo.stride;
            vs->strideType = -1;
            vs->indexIntoShaderNames = key; // lots of assumptions here
            vs->location = -1;
            ++strideCount;
        }
        
        if( skin )
        {
            VertexStride * vs = &mg->_strides[ strideCount ];
            vs->glType = GL_FLOAT;
            vs->numSize = sizeof(float);
            vs->numbersPerElement = numInfluencingJoints;
            vs->strideType = -1;
            vs->indexIntoShaderNames = MSKBoneWeights;
            vs->location = -1;
            ++strideCount;
        }
        mg->_numStrides = strideCount;
        
        [geometries addObject:mg];
    }
    
    [imd->_sources each:^(id key, IncomingSourceTag * ist) {
        if( ist->_bufferInfo.data )
            free( ist->_bufferInfo.data );
    }];

    if( flattenedJointWeightIndex )
        free(flattenedJointWeightIndex);
    
    return geometries;
}

-(MeshScene *)finalAssembly
{
    MeshScene * scene = [MeshScene new];
    
    NSMutableDictionary * meshNodes  = [NSMutableDictionary new];
    NSMutableDictionary * jointNodes = [NSMutableDictionary new];
    
    // Pass 1: create appropriate runtime nodes
    
    static void (^passOne)(id, IncomingNode *) = nil;
    
    passOne = ^(id key, IncomingNode *inode)
    {
        if( inode->_msnType == MSNT_Armature )
        {
            MeshSceneArmatureNode * msan = [MeshSceneArmatureNode new];
            msan->_transform = inode->_transform;
            msan->_name      = inode->_id;
            msan->_sid       = inode->_sid;
            msan->_type      = inode->_msnType;
            jointNodes[inode->_id] = msan;
        }
        else if( (inode->_msnType & MSNT_SomeKindaMeshWereIn) != 0 )
        {
            MeshSceneMeshNode * msmn = [[MeshSceneMeshNode alloc] init];
            msmn->_location  = inode->_location;
            msmn->_rotationX = inode->_rotationX;
            msmn->_rotationY = inode->_rotationY;
            msmn->_rotationZ = inode->_rotationZ;
            msmn->_scale     = inode->_scale;
            msmn->_name      = inode->_id;
            msmn->_type      = inode->_msnType;
            meshNodes[inode->_id] = msmn;
        }
        if( inode->_children )
           [inode->_children each:passOne];
    };

    [_nodes each:passOne];
    
    // Pass 2. Parent runtime nodes
    
    static void (^passTwo)(id, IncomingNode *) = nil;
    
    passTwo = ^(id key, IncomingNode *inode)
    {
        if( inode->_msnType == MSNT_Armature )
        {
            MeshSceneArmatureNode * runtimeNode = jointNodes[inode->_id];
            IncomingNode * parent = inode->_parent;
            while( parent )
            {
                if( parent->_msnType == MSNT_Armature )
                {
                    MeshSceneArmatureNode * runtimeParent = jointNodes[parent->_id];
                    [runtimeParent addChild:runtimeNode name:runtimeNode->_name];
                    break;
                }
                parent = parent->_parent;
            }
        }
        else if( (inode->_msnType & MSNT_SomeKindaMeshWereIn) != 0 )
        {
            MeshSceneMeshNode * runtimeNode = meshNodes[inode->_id];
            IncomingNode * parent = inode->_parent;
            while( parent )
            {
                if( (parent->_msnType & MSNT_SomeKindaMeshWereIn) != 0 )
                {
                    MeshSceneMeshNode * runtimeParent = meshNodes[parent->_id];
                    [runtimeParent addChild:runtimeNode name:runtimeNode->_name];
                    break;
                }
                parent = parent->_parent;
            }
        }
        if( inode->_children )
           [inode->_children each:passTwo];        
    };
    
    [_nodes each:passTwo];
    
    passTwo = nil;
    
    // Pass 3: isolate top of the trees
    
    scene->_meshes = [[meshNodes mapReduce:^id(id key, MeshSceneNode *node) {
        if( ((node->_type & MSNT_SomeKindaMeshWereIn) != 0) && !node->_parent )
            return node;
        return nil;
    }] allValues];
    
    scene->_joints = [[jointNodes mapReduce:^id(id key, MeshSceneNode *node) {
        if( node->_type == MSNT_Armature && !node->_parent )
            return node;
        return nil;
    }] allValues];
    
    if( scene->_joints )
        [scene calcMatricies];

    // Pass 4. Hook up geometries and skins
    
    static MeshSceneArmatureNode *  (^_findJointWithName)(NSString *,MeshSceneArmatureNode *) = nil;
    
    _findJointWithName = ^MeshSceneArmatureNode * (NSString *name,MeshSceneArmatureNode *node)
    {        
        if( EQSTR(name, node->_sid) || EQSTR(name, node->_name) )
            return node;
        
        if( node->_children )
        {
            for( NSString * nodeName in node->_children )
            {
                MeshSceneArmatureNode * child = node->_children[nodeName];
                MeshSceneArmatureNode * retNode = _findJointWithName(name,child);
                if( retNode )
                    return retNode;
            }
        }
        
        return nil;
    };
    
    static MeshSceneArmatureNode *  (^findJointWithName)(NSString *,MeshSceneArmatureNode *) = nil;
    
    findJointWithName = ^MeshSceneArmatureNode * (NSString *name,MeshSceneArmatureNode *node)
    {
        MeshSceneArmatureNode * joint = jointNodes[name];
        
        if( joint )
            return joint;

        for( NSString * jname in jointNodes )
        {
            joint = _findJointWithName(name,jointNodes[jname]);
            if( joint )
                return joint;
        }
        return nil;
    };
    
    static void (^passFour)(id,IncomingNode*) = nil;
    
    passFour = ^(id key, IncomingNode *inode)
    {
        if( inode->_msnType == MSNT_Mesh )
        {
            MeshSceneMeshNode * runtimeNode = meshNodes[inode->_id];
            
            IncomingMeshData * meshData      = _geometries[inode->_geometryName];
            
            runtimeNode->_geometries = [self buildOpenGlBuffer:meshData skin:nil];
        }
        else if( inode->_msnType == MSNT_SkinnedMesh )
        {
            MeshSkinning * sceneSkin = [MeshSkinning new];
            IncomingSkin * iskin = _skins[ inode->_skinName];
            
            sceneSkin->_bindShapeMatrix             = iskin->_bindShapeMatrix;
            sceneSkin->_influencingJointCounts      = iskin->_weights->_vcounts;
            sceneSkin->_numInfluencingJointCounts   = iskin->_weights->_numVcounts;
            sceneSkin->_packedWeightIndices         = iskin->_weights->_weights;
            sceneSkin->_numPackedWeightIndicies     = iskin->_weights->_numWeights;
            
            for( int i = 0; i < iskin->_weights->_nextInput; i++ )
            {
                SkinSemanticKey sskey = iskin->_weights->_semanticKey[i];
                if( sskey == SSKJoint )
                    sceneSkin->_jointWOffset = iskin->_weights->_offsets[i];
                else
                    sceneSkin->_weightFOffset = iskin->_weights->_offsets[i];
            }
            
            NSArray * jointNameArray;
            for( IncomingSkinSource * iss in iskin->_incomingSources )
            {
                if( EQSTR(iss->_paramName, kValue_name_JOINT) )
                {
                    jointNameArray = iss->_nameArray;
                    break;
                }
            }
            
            for( IncomingSkinSource * iss in iskin->_incomingSources )
            {
                if( EQSTR(iss->_paramName, kValue_name_TRANSFORM) )
                {
                    GLKMatrix4 * mats = (GLKMatrix4 *)(iss->_data);
                    
                    for( NSString * jointName in jointNameArray )
                    {
                        MeshSceneArmatureNode * joint = findJointWithName(jointName,nil);
                        joint->_invBindMatrix = GLKMatrix4Transpose(*mats++);
                    }
                }
                else if( EQSTR(iss->_paramName, kValue_name_WEIGHT) )
                {
                    sceneSkin->_weights = iss->_data;
                    sceneSkin->_numWeights = iss->_numFloats;
                }
            }
            for( NSString * jointName in jointNameArray )
            {
                MeshSceneArmatureNode * joint = findJointWithName(jointName,nil);
                [sceneSkin->_influencingJoints addObject:joint];
            }
            
            MeshSceneMeshNode * runtimeNode = meshNodes[inode->_id];
            runtimeNode->_skin = sceneSkin;
            runtimeNode->_geometries = [self buildOpenGlBuffer:_geometries[iskin->_meshSource] skin:sceneSkin];
        }
        
//        if( _up != 'y' )
//            [self turnUp:sceneGeometry->_buffers];
        
        if( inode->_children )
            [inode->_children each:passFour];
    };
            

    [_nodes each:passFour];
    
    // Pass 5. Materials
    
    static void (^passFive)( id, IncomingNode *) = nil;
    
    passFive = ^(id key, IncomingNode *inode ) {
        
        if( (inode->_msnType & (MSNT_Mesh|MSNT_SkinnedMesh)) != 0 )
        {
            IncomingMeshData * meshData;

            if( inode->_geometryName )
                meshData = _geometries[ inode->_geometryName ];
            else {
                IncomingSkin * skin = _skins[ inode->_skinName ];
                meshData = _geometries[ skin->_meshSource ];
            }
            
            NSMutableDictionary * materials = nil;
            
            for( IncomingPolygonIndex * ipi in meshData->_polygonTags )
            {
                if( ipi->_materialName )
                {
                    IncomingMaterial * im = _materials[ _materialBindings[ ipi->_materialName ] ];
                    IncomingEffect   * ie = _effects[ im->_effect ];
                    MeshMaterial     *  mm = [MeshMaterial new];
                    mm->_colors = ie->_colors;
                    mm->_shininess = ie->_shininess;
                    mm->_doSpecular = EQSTR( ie->_type, kTag_phong );
                    
                    if( ie->_textureName )
                    {
                        mm->_colors.diffuse = (GLKVector4){ 1, 1, 1, 1 };
                        
                        IncomingNewParam * inp = ie->_newParams[ie->_textureName];
                        if( inp && EQSTR(inp->_tag, kTag_sampler2D) )
                        {
                            inp = ie->_newParams[ inp->_content ];
                            if( inp && EQSTR(inp->_tag, kTag_surface) )
                            {
                                IncomingImage * ii = _images[ inp->_content];
                                if( ii )
                                    mm->_textureFileName = [ii->_init_from lastPathComponent];
                            }
                        }
                        
                        if( !mm->_textureFileName )
                        {
                            TGLog(LLShitsOnFire, @"Could not dig out a texture file name for %@", ie->_textureName);
                            exit(-1);
                        }
                    }
                    if( !materials )
                        materials = [NSMutableDictionary new];
                    materials[ipi->_materialName] = mm;
                }
            }
            
            MeshSceneMeshNode * runtimeNode = meshNodes[inode->_id];
            runtimeNode->_materials = materials;
        }
        
        if( inode->_children )
            [inode->_children each:passFive];
    };
    
    [_nodes each:passFive];

    if( [_animations count] )
    {
        NSMutableArray * sceneAnimations = [NSMutableArray new];
        
        for( NSString * namePath in _animations )
        {
            NSArray * parts = [namePath componentsSeparatedByString:@"/"];
            
            MeshAnimation * sceneAnim = _animations[namePath];
            
#ifdef CULL_NULL_ANIMATIONS
            GLKMatrix4 * firstMat = &sceneAnim->_transforms[0];
            
            bool allSame = true;
            for( int a = 1; a < sceneAnim->_numFrames; a++ )
            {
                if( !EQMAT4((*firstMat), sceneAnim->_transforms[a]) )
                {
                    allSame = false;
                    break;
                }
            }

            if( !allSame )
#endif
            {
                MeshSceneArmatureNode * joint = findJointWithName(parts[0],nil);
                if( joint )
                {
                    sceneAnim->_target = joint;
                }
                else
                {
                    TGLog(LLShitsOnFire, @"Can't find the target joint animation node: %@/%@ (yea, it has to be joint)", parts[0],parts[1]);
                }
                sceneAnim->_property = parts[1];
                [sceneAnimations addObject:sceneAnim];
            }
        }
        
        scene->_animations = [NSArray arrayWithArray:sceneAnimations];
        
    }
    else
    {
        scene->_animations = nil;
    }
    
    // Faust says:
    // release blocks b/c they hold refs to self
    passOne = nil;
    passTwo = nil;
    passFour = nil;
    passFive = nil;
    _findJointWithName = nil;
    findJointWithName = nil;
    
    return scene;
}
@end

@implementation ColladaParser

+(MeshScene *)parse:(NSString *)fileName
{
    ColladaParserImpl * cParser = [[ColladaParserImpl alloc] init];
    
    NSString * fileBaseName = [fileName stringByDeletingPathExtension];
    
    NSString *      path = [[NSBundle mainBundle] pathForResource:fileBaseName
                                                      ofType:[fileName pathExtension]];    
    NSData *        data = [[NSData alloc] initWithContentsOfFile:path];
    NSXMLParser * parser = [[NSXMLParser alloc] initWithData:data];
    
    [parser setDelegate:cParser];
    bool success = [parser parse]; 
    if( success )
    {
        MeshScene * scene = [cParser finalAssembly];
        scene.fileName = fileBaseName;
        return scene;
    }
    return nil;
}

@end