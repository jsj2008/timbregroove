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
    
} ColladaTagState;

#define SET(f)      _state |= f
#define UNSET(f)    _state &= ~f
#define CHECK(f)    ((_state & f) == f)
#define CHECKANY(f) CHECK(f)


#define EQSTR(a,b) (a && ([a caseInsensitiveCompare:b] == NSOrderedSame))

#define EQMAT4(a,b) ( memcmp(a.m,b.m,sizeof(a.m)) == 0 )


static float * parseFloats(NSString * str, int * numFloats)
{
    str = [str stringByTrimmingCharactersInSet:
           [NSCharacterSet whitespaceCharacterSet]];
    NSArray * burp = [str componentsSeparatedByString:@" "];
    unsigned long count = [burp count];
    float * p = malloc(sizeof(float)*count);
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
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@ IncomingVertexData  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@interface IncomingSourceTag : NSObject {
@public
    MeshGeometryBuffer _meta;

    NSString *  _id;
    NSString *  _redirectTo;
}
@end
@implementation IncomingSourceTag
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingMeshData @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@interface IncomingMeshData : NSObject {
@public
    NSString *             _geometryName;
    NSMutableDictionary *  _sources;        // vertex data here
    NSMutableArray *       _polygonTags;    // index data here
    
    IncomingSourceTag *   _tempIncomingSourceTag;
    

    // filled in at finalize
    MeshGeometry *         _meshGeometry;
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

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingMaterial @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

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


NSString  *  PhongColorNames[PhongColor_NUM_COLORS];
NSString *  PhongFloatNames[PhongValue_NUM_FLOATS];

@interface IncomingPhong : NSObject {
@public
    GLKVector4 _colors[PhongColor_NUM_COLORS];
    float      _floats[PhongValue_NUM_FLOATS];
    
    NSString * _transparent_opaque_type; // 'RGB_ZERO'
    
    PhongColors _expectingColor;
    PhongFloat _expectingFloat;
}
@end

@implementation IncomingPhong
-(id)init
{
    self = [super init];
    if( self )
    {
        if( !PhongColorNames[0] )
        {
            PhongColorNames[PhongColor_Emission] = kTag_emission;
            PhongColorNames[PhongColor_Ambient] = kTag_ambient;
            PhongColorNames[PhongColor_Diffuse] = kTag_diffuse;
            PhongColorNames[PhongColor_Specular] = kTag_specular;
            PhongColorNames[PhongColor_Reflective] = kTag_reflective;
            PhongColorNames[PhongColor_Transparent] = kTag_transparent;
            PhongFloatNames[PhongValue_Shininess] = kTag_shininess;
            PhongFloatNames[PhongValue_Reflectivity] = kTag_reflectivity;
            PhongFloatNames[PhongValue_Transparency] = kTag_transparency;
        }
        
        _expectingColor = PhongColor_None;
        _expectingFloat = PhongValue_None;
    }
    return self;
}
@end

@interface IncomingEffect : NSObject {
    @public
    NSString * _id;
    NSString * _type; // 'phong'
    
    IncomingPhong * _phong;
    
}
@end

@implementation IncomingEffect
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
        _up         = 'y';
    }
    return self;
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
            
            [meshData->_polygonTags addObject:polyTag];
            
            SET(kColStatePolyIndices);
            return;
        }
        
        if( CHECKANY(kColStateInSource) )
        {
            if( EQSTR(elementName, kTag_float_array) )
            {
                SET(kColStateFloatArray);
                return;
            }
            
            if( EQSTR(elementName,kTag_accessor) )
            {
                IncomingSourceTag * ims = meshData->_tempIncomingSourceTag;
                ims->_meta.numElements = scanInt(attributeDict[kAttr_count]);
                ims->_meta.stride      = scanInt(attributeDict[kAttr_stride]);
                return;
            }
        }
        
        if( CHECKANY(kColStateInVertices) )
        {
            if( EQSTR(elementName,kTag_input) )
            {
                IncomingSourceTag * ims = meshData->_tempIncomingSourceTag;
                ims->_redirectTo = [(NSString *)attributeDict[kAttr_source] substringFromIndex:1];
            }
            
            return;
        }
        
        if( CHECKANY(kColStatePolyIndices) )
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
        if( CHECKANY(kColStateInVertices) )
        {
            IncomingSourceTag * ivd = meshData->_tempIncomingSourceTag;
            meshData->_sources[ivd->_id] = ivd;
            meshData->_tempIncomingSourceTag = nil;
            UNSET(kColStateInVertices);
            return;
        }
        
        if( CHECKANY(kColStatePolyIndices) )
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

        if( CHECKANY(kColStateInSource) )
        {
            if( EQSTR(elementName, kTag_source) )
            {
                IncomingSourceTag * ivd = meshData->_tempIncomingSourceTag;
                ivd->_meta.numFloats = _floatArrayCount;
                ivd->_meta.data = _floatArray;
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
        
        
        if( CHECKANY(kColStateVertexWeights) )
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
        
        if( CHECKANY(kColStateVertexWeights) )
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
        if( CHECKANY(kColStateInNode) )
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
        if( CHECKANY(kColStateInNode) )
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
        
        if( CHECKANY(kColStateMaterialTag) )
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
        if( CHECKANY(kColStateMaterialTag) )
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
        if( CHECKANY(kColStateEffectTag) )
        {
            IncomingEffect * ie = _incoming;
            
            if( CHECKANY(kColStatePhong) )
            {
                IncomingPhong * im = ie->_phong;

                if( im->_expectingColor != PhongColor_None )
                {
                    if( EQSTR(elementName, kTag_color) )
                    {
                        SET(kColStateFloatArray);
                        return;
                    }
                }
                
                if( im->_expectingFloat != PhongValue_None )
                {
                    if( EQSTR(elementName, kTag_float) )
                    {
                        SET(kColStateFloat);
                        return;
                    }
                }
                
                for( int i = 0; i < PhongColor_NUM_COLORS; i++ )
                {
                    if( EQSTR(elementName, PhongColorNames[i]) )
                    {
                        im->_expectingColor = i;
                        if( i == PhongColor_Transparent )
                            im->_transparent_opaque_type = attributeDict[kAttr_opaque];
                        return;
                    }
                }
                
                for( int f = 0; f < PhongValue_NUM_FLOATS; f++ )
                {
                    if( EQSTR(elementName, PhongFloatNames[f]) )
                    {
                        im->_expectingFloat = f;
                        return;
                    }
                }

            }
            
            if( EQSTR(elementName, kTag_phong) )
            {
                IncomingEffect * ie = _incoming;
                ie->_phong = [IncomingPhong new];
                SET(kColStatePhong);
                return;
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
        if( CHECKANY(kColStateEffectTag) )
        {
            IncomingEffect * ie = _incoming;
            
            if( CHECKANY(kColStatePhong) )
            {
                if( EQSTR(elementName, kTag_phong) )
                {
                    UNSET(kColStatePhong);
                    return;
                }
                
                IncomingPhong * im = ie->_phong;
                
                if( EQSTR(elementName, kTag_color) )
                {
                    im->_colors[ im->_expectingColor ] = *(GLKVector4 *)_floatArray;
                    im->_expectingColor = PhongColor_None;
                    _floatArray = NULL;
                    _floatArrayCount = 0;
                    return;
                }
                
                if( EQSTR(elementName, kTag_float) )
                {
                    im->_floats[ im->_expectingFloat ] = [_floatString floatValue];
                    im->_expectingFloat = PhongValue_None;
                    _floatString = nil;
                    return;
                }
                
            }
            
            if( EQSTR(elementName, kTag_effect) )
            {
                _incoming = nil;
                SET(kColStateEffectTag);
                return;
            }
        }
        
    }
}

-(void)    parser:(NSXMLParser *)parser
  didStartElement:(NSString *)elementName
     namespaceURI:(NSString *)namespaceURI
    qualifiedName:(NSString *)qualifiedName
       attributes:(NSDictionary *)attributeDict
{
    if( CHECKANY(kColStateInAnimation) )
    {
        [self handleAnimation:elementName attributes:attributeDict];
        return;
    }
    
    if( CHECKANY(kColStateInMeshGeometry) )
    {
        [self handleMeshGeometry:elementName attributes:attributeDict];
        return;
    }
    
    if( CHECKANY(kColStateSkin) )
    {
        [self handleSkin:elementName attributes:attributeDict];
        return;
    }
    
    if( CHECKANY(kColStateVisualScene) )
    {
        [self handleScene:elementName attributes:attributeDict];
        return;
    }
    
    if( CHECKANY(kColStateMaterialLibrary) )
    {
        [self handleMaterials:elementName attributes:attributeDict];
        return;
    }
    
    if( CHECKANY(kColStateEffectLibrary) )
    {
        [self handleEffects:elementName attributes:attributeDict];
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
    
}

-(void)  parser:(NSXMLParser *)parser
foundCharacters:(NSString *)string
{
    if( CHECKANY(kColStateFloatArray) )
    {
        if( _floatString )
            [_floatString appendString:string];
        else
            _floatString = [NSMutableString stringWithString:string];
        return;
    }
    
    if( CHECKANY(kColStateFloat) )
    {
        _floatString = [NSMutableString stringWithString:string];
        UNSET(kColStateFloat);
        return;
    }
    
    if( CHECKANY(kColStateIntArray) )
    {
        if( _ushortString )
           [_ushortString appendString:string];
        else
            _ushortString = [NSMutableString stringWithString:string];
        return;
    }
    
    if( CHECKANY(kColStateStringArray) )
    {
        if( _stringArrayString )
           [_stringArrayString appendString:string];
        else
            _stringArrayString = [NSMutableString stringWithString:string];
        return;
    }
    
    if( CHECKANY(kColStateCaptureText) )
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

    if( CHECKANY(kColStateStringArray) )
    {
        UNSET(kColStateStringArray);
        if( EQSTR(elementName, kTag_Name_array) )
            return;
    }
    
    if( CHECKANY(kColStateFloatArray) )
    {
        _floatArray = parseFloats(_floatString, &_floatArrayCount);
        _floatString = nil;
        UNSET(kColStateFloatArray);
        
        if( EQSTR(elementName,kTag_float_array) )
            return;
    }
    
    if( CHECKANY(kColStateIntArray) )
    {
        _ushortArray = parseUShorts(_ushortString, &_ushortArrayCount);
        _ushortString = nil;
        UNSET(kColStateIntArray);
        // return;
    }
    
    if( CHECKANY(kColStateSkin) )
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
    
    if( CHECKANY(kColStateInAnimation) )
    {
        if( EQSTR(elementName,kTag_animation) )
        {
            [self assembleAnimation];
            return;
        }
        
        [self handleAnimation:elementName attributes:nil];
        return;
    }
    
    if( CHECKANY(kColStateInMeshGeometry) )
    {
        if( EQSTR(elementName,kTag_geometry) )
        {
            [self assembleGeometry];
            return;
        }
        
        [self handleMeshGeometry:elementName attributes:nil];
        return;
    }
    
    if( CHECKANY(kColStateVisualScene) )
    {
        if( EQSTR(elementName, kTag_visual_scene) )
        {
            [self assembleScene];
            return;
        }
        
        [self handleScene:elementName attributes:nil];
        return;
    }
    
    if( CHECKANY(kColStateMaterialLibrary) )
    {
        if( EQSTR(elementName, kTag_library_materials) )
        {
            UNSET(kColStateMaterialLibrary);
            return;
        }
        
        [self handleMaterials:elementName attributes:nil];
        return;
    }

    if( CHECKANY(kColStateEffectLibrary) )
    {
        if( EQSTR(elementName, kTag_library_effects) )
        {
            UNSET(kColStateEffectLibrary);
            return;
        }
        
        [self handleEffects:elementName attributes:nil];
    }
    
    if( CHECKANY(kColStateUp) )
    {
        if( EQSTR(_captureString, @"Z_UP") )
            _up = 'z';
        UNSET(kColStateUp);
    }

}

-(void) flatten:(MeshGeometryBuffer *)b
          index:(MeshGeometryIndexBuffer *)index
numIndexBuffers:(unsigned int)numIndexBuffers
{
    unsigned int totalNumberOfIndices = 0;
    for( int ii = 0; ii < numIndexBuffers; ii++ )
    {
        totalNumberOfIndices += index[ii].numIndices;
    }
    
    unsigned int elementSize = b->stride;
    float * newBuffer = malloc( sizeof(float) * totalNumberOfIndices * elementSize);
    float * p = newBuffer;
    float * old = b->data;
    
    for( int nn = 0; nn < numIndexBuffers; nn++ )
    {
        unsigned int * idx = index[nn].indexData;
        int i;
        for( int x = 0; x < index[nn].numIndices; x++ )
        {
            i = *idx++ * elementSize;
            for( int e = 0; e < elementSize; e++ )
                *p++ = old[i + e];
        }
        free(index[nn].indexData);        
    }
    free(b->data);
    b->data = newBuffer;
    
    b->numFloats = totalNumberOfIndices * elementSize;
    b->numElements = totalNumberOfIndices;
}

-(void)repackPolyIndex:(IncomingPolygonIndex *)polyTag
                offset:(unsigned int)offset
       primitiveStride:(unsigned int)primitiveStride
          bufferTarget:(MeshGeometryIndexBuffer *)bufferTarget
{
    unsigned short * primitives    = polyTag->_primitives;
    unsigned int     numPrimitives = polyTag->_numPrimitives;
    unsigned short * vectorCounts  = polyTag->_vectorCounts;
    
    unsigned int     vectorCountIndex = 0;
    unsigned int     primitiveIndex   = 0;
    unsigned int *   newIndexBuffer   = malloc( sizeof(unsigned int) * numPrimitives * 5 );
    unsigned int     newIBufferIdx    = 0;
    
    while(  primitiveIndex < numPrimitives )
    {
        int vectorPerShape = 3;
        if( vectorCounts )
            vectorPerShape = vectorCounts[ vectorCountIndex++ ];
        
        int oldIBufferIdx;
        
        if( vectorPerShape > 3 )
        {
            // triangulate
            unsigned short oldIndices[10];
            for( unsigned int v = 0; v < vectorPerShape; v++ )
            {
                oldIBufferIdx = primitiveIndex + ( v * primitiveStride ) + offset;
                oldIndices[v] = primitives[ oldIBufferIdx ];
            }
            
            for( unsigned int k = 1; k < vectorPerShape-1; k++ )
            {
                newIndexBuffer[newIBufferIdx++] = oldIndices[ 0 ];
                newIndexBuffer[newIBufferIdx++] = oldIndices[ k ];
                newIndexBuffer[newIBufferIdx++] = oldIndices[ k + 1 ];
            }
        }
        else
        {
            for( unsigned int v = 0; v < vectorPerShape; v++ )
            {
                oldIBufferIdx = primitiveIndex + ( v * primitiveStride ) + offset;
                newIndexBuffer[newIBufferIdx++] = primitives[ oldIBufferIdx ];
            }
        }
        primitiveIndex += primitiveStride * vectorPerShape;
    }
    
    bufferTarget->indexData  = realloc(newIndexBuffer, sizeof(unsigned int) * newIBufferIdx);
    bufferTarget->numIndices = newIBufferIdx;
}

-(void)repackTriangleIndex:(IncomingPolygonIndex *)polyTag
                    offset:(unsigned int)offset
           primitiveStride:(unsigned int)primitiveStride
              bufferTarget:(MeshGeometryIndexBuffer *)bufferTarget
{
    unsigned short * primitives    = polyTag->_primitives;
    unsigned int     numPrimitives = polyTag->_numPrimitives;
    
    unsigned int     newIndexCount    = numPrimitives / primitiveStride;
    unsigned int *   newIndexBuffer   = malloc( sizeof(unsigned int) * newIndexCount);
                                               
    for( int i = 0; i < newIndexCount; i++ )
    {
        int value = primitives[ i * primitiveStride + offset];
        newIndexBuffer[i] = value;
    }
    
    bufferTarget->indexData  = newIndexBuffer;
    bufferTarget->numIndices = newIndexCount;
}

-(void)turnUp:(MeshGeometryBuffer *)bufferInfo
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
-(void)applyBindMatrix:(MeshGeometryBuffer *)bufferInfo
            bindMatrix: (GLKMatrix4)bindMatrix
{
    GLKVector3 * buffer = (GLKVector3 *)bufferInfo->data;
    for( int i = 0; i < bufferInfo->numElements; i++ )
    {
        buffer[i] = GLKMatrix4MultiplyVector3(bindMatrix, buffer[i]);
    }
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
    
    
    static MeshGeometry *  (^massageGeometry)(NSString *) = nil;
    
    massageGeometry = ^MeshGeometry * (NSString *name) {
        MeshGeometry     * sceneGeometry = [MeshGeometry new];
        IncomingMeshData * meshData      = _geometries[name];

        meshData->_meshGeometry = sceneGeometry;

        
        // Step 1.
        // -----------------------------------------------------------
        // Populate the MeshGeometryBuffer structures for
        // each semantic (UV, vertex, normal, etc.) with data & stride information
        
        // Big assumption(?): the indices in all triangle/polylist tags in this
        // mesh all refer to the same buffer data (sources) with the same semantics
        // and same offsets
        
        IncomingPolygonIndex * firstPolyIndexTag = meshData->_polygonTags[0];

        // FYI 'primitives' refers to Collada's <p> tag
        
        NSString * srcName;
        int primitiveStride = 0;
        unsigned int primitivesOffset[kNumMeshSemanticKeys];
        
        for( int i = 0; i < firstPolyIndexTag->_nextInput; i++ )
        {
            srcName = firstPolyIndexTag->_sourceURL[i];
            IncomingSourceTag * sourceTag = meshData->_sources[srcName];
            if( sourceTag->_redirectTo )
                sourceTag = meshData->_sources[sourceTag->_redirectTo];
            
            MeshSemanticKey key = firstPolyIndexTag->_semanticKey[i];
            
            primitivesOffset[key] = firstPolyIndexTag->_offsets[i];
            
            // The info is already there in the source tag,
            // just copy it over...
            sceneGeometry->_buffers[key] = sourceTag->_meta;
            
            int thisOffset = primitivesOffset[key] + 1;
            if( thisOffset > primitiveStride )
                primitiveStride = thisOffset;
        }

        // Step 2.
        // -----------------------------------------------------------
        // Extract (de-interlace) the relevant index buffer from
        // the Triangle/Polylist tag for each buffer semantic
        // e.g. Normal, UV, Vertex, etc.
        
        
        int numPolyTags = [meshData->_polygonTags count];
        int polyTagIndexCount = 0;
        
        size_t sz = sizeof(MeshGeometryIndexBuffer) * numPolyTags * kNumMeshSemanticKeys;
        MeshGeometryIndexBuffer * tempDeinterlacedIndexBuffers = malloc(sz);
        memset(tempDeinterlacedIndexBuffers, 0, sz);
        
        for( IncomingPolygonIndex * polyIndexTag in meshData->_polygonTags )
        {
            bool triangulated = [self isTriangulated:polyIndexTag];
            
            for( MeshSemanticKey key = 0; key < kNumMeshSemanticKeys; key++ )
            {
                MeshGeometryBuffer *buffer = sceneGeometry->_buffers + key;
                
                if( buffer->data )
                {
                    MeshGeometryIndexBuffer extractedIndexBuffers = { 0, 0 };
                    
                    // N.B. these do a malloc()
                    
                    if( triangulated )
                        [self repackTriangleIndex:polyIndexTag
                                           offset:primitivesOffset[key]
                                  primitiveStride:primitiveStride
                                     bufferTarget:&extractedIndexBuffers];
                    else
                        [self repackPolyIndex:polyIndexTag
                                       offset:primitivesOffset[key]
                              primitiveStride:primitiveStride
                                 bufferTarget:&extractedIndexBuffers];
                    
                    tempDeinterlacedIndexBuffers[ (key * numPolyTags) + polyTagIndexCount ] = extractedIndexBuffers;
                }
            }
            
            if(polyIndexTag->_primitives)
                free(polyIndexTag->_primitives);
            if(polyIndexTag->_vectorCounts)
                free(polyIndexTag->_vectorCounts);
            
            ++polyTagIndexCount;
        }
        
        // Step 3.
        // -----------------------------------------------------------
        // flatten all semantic buffers (except for the vertex/shapes)
        // b/c OpenGL only allows one index per shader call
        
        for( MeshSemanticKey key = 0; key < kNumMeshSemanticKeys; key++ )
        {
            MeshGeometryBuffer *buffer = sceneGeometry->_buffers + key;
            
            if( buffer->data )
            {
                if( key == MSKPosition )
                {
                    size_t sz = sizeof(MeshGeometryIndexBuffer) * numPolyTags;
                    sceneGeometry->_indexBuffers = malloc(sz);
                    memcpy(sceneGeometry->_indexBuffers, &tempDeinterlacedIndexBuffers[MSKPosition], sz );
                    sceneGeometry->_numIndexBuffers = numPolyTags;
                }
                else
                {
                    [self flatten:buffer
                            index:&tempDeinterlacedIndexBuffers[ key * numPolyTags ]
                  numIndexBuffers:numPolyTags];
                }
            }
        }
        
        if( _up != 'y' )
            [self turnUp:sceneGeometry->_buffers];
        
        return sceneGeometry;
    };
    

    static void (^mapGeometry)(id,IncomingNode*) = nil;
    
    mapGeometry = ^(id key, IncomingNode *inode)
    {
        if( inode->_msnType == MSNT_Mesh )
        {
            MeshSceneMeshNode * runtimeNode = meshNodes[inode->_id];
            runtimeNode->_geometry = massageGeometry( inode->_geometryName );
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
            runtimeNode->_geometry = massageGeometry( iskin->_meshSource );
            
            [self applyBindMatrix:runtimeNode->_geometry->_buffers
                       bindMatrix:sceneSkin->_bindShapeMatrix];
        }
        
        if( inode->_children )
            [inode->_children each:mapGeometry];
    };
            

    // Pass 4. Hook up geometries and skins
    
    [_nodes each:mapGeometry];
    
    
    if( [_animations count] )
    {
        static MeshSceneMeshNode * (^findMeshNodeWithGeometryName)(NSString *) = nil;
        
        findMeshNodeWithGeometryName = ^MeshSceneMeshNode *(NSString *name)
        {
            MeshSceneMeshNode * meshNode = meshNodes[name];
            if( meshNode )
                return meshNode;
            IncomingMeshData * imd = _geometries[name];
            if( !imd )
                return nil;
            for( NSString * mname in meshNodes )
            {
                meshNode = meshNodes[mname];
                if( meshNode->_geometry ==  imd->_meshGeometry )
                    return meshNode;
            }
            return nil;
        };
        
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
                    sceneAnim->_target = findMeshNodeWithGeometryName(parts[0]);
                }
                if( !sceneAnim->_target )
                    TGLog(LLShitsOnFire, @"Can't find the target animation node: %@/%@", parts[0],parts[1]);
                
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