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

typedef enum _ColladaTagState
{
    kColStateInAnimation = 1,
    kColStateFloatArray = 1 << 1,
    kColStateInMeshGeometry = 1 << 2,
    kColStateInSource = 1 << 3,
    kColStateInVertices = 1 << 4,
    kColStateTriangles = 1 << 5,
    kColStateIntArray = 1 << 6,
    kColStateTriangleIntArray = kColStateTriangles | kColStateIntArray,
    kColStateVertexWeights = 1 << 7,
    kColStateSkin = 1 << 8,
    kColStateSkinSource = kColStateSkin | kColStateInSource,
    kColStateInStringArray = 1 << 9,
    kColStateJoint = 1 << 10,
    kColStateVisualScene = 1 << 11,
    kColStateInNode = 1 << 12,
    kColStateCaptureText = 1 << 13,
    kColStateUp = 1 << 14,
    
    
} ColladaTagState;

#define SET(f)      _state |= f
#define UNSET(f)    _state &= ~f
#define CHECK(f)    ((_state & f) == f)
#define CHECKANY(f) ((_state & f) != 0)


#define EQSTR(a,b) ([a caseInsensitiveCompare:b] == NSOrderedSame)

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

@interface IncomingTriangleTag : NSObject {
@public
    int              _count;
    MeshSemanticKey  _semanticKey[kNumMeshSemanticKeys];
    int              _offsets[kNumMeshSemanticKeys];
    NSMutableArray * _source;
    unsigned short * _primitives;
    unsigned short * _vectorCounts;
    
    int              _numPrimitives;
    int              _nextInput;
}

@end
@implementation IncomingTriangleTag

- (id)init
{
    self = [super init];
    if (self) {
        _source = [NSMutableArray new];
    }
    return self;
}
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@ IncomingVertexData  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@interface IncomingVertexData : NSObject {
@public
    MeshGeometryBuffer _meta;

    NSString *  _id;
    NSString *  _redirectTo;
}
@end
@implementation IncomingVertexData
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingMeshData @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@interface IncomingMeshData : NSObject {
@public
    NSString *             _geometryName;
    NSMutableDictionary *  _vertexDict;
    
    IncomingVertexData *   _vertexData;
    IncomingTriangleTag *  _triangleTag;
}
@end
@implementation IncomingMeshData
- (id)init
{
    self = [super init];
    if (self) {
        _vertexDict = [NSMutableDictionary new];
    }
    return self;
}
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingSkinSource @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@interface IncomingSkinSource : NSObject {
@public
    NSString * _id;
    int       _count;
    NSString * _source;
    int _accCount;
    int _stride;
    NSArray * _nameArray;
    float * _data;
    int _numFloats;
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
    int _count;
    SkinSemanticKey _semanticKey[kNumSkinSemanticKeys]; // N.B. these are NOT ordered
    int _offsets[kNumSkinSemanticKeys];
    NSMutableArray * _sources;
    unsigned short * _vcounts;
    unsigned short * _weights;
    unsigned int _numVcounts;
    unsigned int _numWeights;
    
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
    NCSRoationX = 1 << 1,
    NCSRoationY = 1 << 2,
    NCSRoationZ = 1 << 3,
    NCSScale = 1 << 4
} NodeCoordSpec;

@interface IncomingNode  : NSObject {
@public
    NSString * _id;
    NSString * _name;
    NSString * _sid;
    NSString * _type;
    
    GLKMatrix4 _transform;
    
    NodeCoordSpec _coordSpec;
    GLKVector3 _location;
    GLKVector3 _rotationX;
    GLKVector3 _rotationY;
    GLKVector3 _rotationZ;
    GLKVector3 _scale;
    
    NSString * _skinName;
    NSString * _skeletonName;
    NSString * _geometryName; // no skinning
    
    NSMutableDictionary * _children;
    NodeCoordSpec         _incomingSpec;
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

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  ColladaParser @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

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
    NSMutableDictionary * _nodeTree;
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
        _nodeTree   = [NSMutableDictionary new];
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
                    ia->_animation->_transforms = (GLKMatrix4 *)_floatArray;
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
        bool bIsSource   = EQSTR(elementName,kTag_source);
        bool bIsVertices = EQSTR(elementName,kTag_vertices);
        if(  bIsSource || bIsVertices )
        {
            IncomingVertexData *ims = [IncomingVertexData new];
            ims->_id = attributeDict[kAttr_id];
            
            meshData->_vertexData = ims;
            
            if( bIsSource )
                SET(kColStateInSource);
            else
                SET(kColStateInVertices);
            return;
        }

        if( EQSTR(elementName, kTag_triangles) || EQSTR(elementName, kTag_polylist) )
        {
            meshData->_triangleTag = [[IncomingTriangleTag alloc] init];
            meshData->_triangleTag->_count = scanInt(attributeDict[kAttr_count]);
            SET(kColStateTriangles);
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
                IncomingVertexData * ims = meshData->_vertexData;
                ims->_meta.numElements = scanInt(attributeDict[kAttr_count]);
                ims->_meta.stride       = scanInt(attributeDict[kAttr_stride]);
                return;
            }
        }
        
        if( CHECKANY(kColStateInVertices) )
        {
            if( EQSTR(elementName,kTag_input) )
            {
                IncomingVertexData * ims = meshData->_vertexData;
                ims->_redirectTo = [(NSString *)attributeDict[kAttr_source] substringFromIndex:1];
            }
            
            return;
        }
        
        if( CHECKANY(kColStateTriangles) )
        {
            if( EQSTR(elementName, kTag_input) )
            {
                IncomingTriangleTag * itt = meshData->_triangleTag;
                int idx = itt->_nextInput;
                
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
                itt->_semanticKey[idx] = sem;
                
                // 2. get offset
                //
                itt->_offsets[idx] = scanInt(attributeDict[kAttr_offset]);
                
                // 3. get source (what this is referring to)
                //
                itt->_source[idx] = [(NSString *)attributeDict[kAttr_source] substringFromIndex:1];
                
                itt->_nextInput++;
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
            IncomingVertexData * ivd = meshData->_vertexData;
            meshData->_vertexDict[ivd->_id] = ivd;
            meshData->_vertexData = nil;
            UNSET(kColStateInVertices);
            return;
        }
        
        if( CHECKANY(kColStateTriangles) )
        {
            if( EQSTR(elementName, kTag_p) )
            {
                IncomingTriangleTag * itt = meshData->_triangleTag;
                itt->_primitives = _ushortArray;
                itt->_numPrimitives = _ushortArrayCount;
                _ushortArrayCount = 0;
                _ushortArray = NULL;
                return;
            }
            
            if( EQSTR(elementName, kTag_vcount) )
            {
                IncomingTriangleTag * itt = meshData->_triangleTag;
                itt->_vectorCounts = _ushortArray;
                _ushortArrayCount = 0;
                _ushortArray = NULL;
                return;
            }
            
            if( EQSTR(elementName, kTag_triangles) || EQSTR(elementName, kTag_polylist) )
            {
                UNSET(kColStateTriangles);
                return;
            }
        }

        if( CHECKANY(kColStateInSource) )
        {
            if( EQSTR(elementName, kTag_source) )
            {
                IncomingVertexData * ivd = meshData->_vertexData;
                ivd->_meta.numFloats = _floatArrayCount;
                ivd->_meta.data = _floatArray;
                _floatArray = NULL;
                _floatArrayCount = 0;
                meshData->_vertexDict[ivd->_id] = ivd;
                
                meshData->_vertexData = nil;
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
        if( CHECK(kColStateSkinSource) )
        {
            if( EQSTR(elementName, kTag_Name_array) )
            {
                SET(kColStateInStringArray);
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
        if( CHECK(kColStateSkinSource) )
        {
            if( EQSTR(elementName, kTag_source) )
            {
                IncomingSkinSource * iss = [iskin->_incomingSources lastObject];
                if( _stringArrayString )
                {
                    iss->_nameArray = parseStringArray(_stringArrayString);
                    _stringArrayString = nil;
                    UNSET(kColStateInStringArray);
                }
                if( _floatArray )
                {
                    iss->_data = _floatArray;
                    iss->_numFloats = _floatArrayCount;
                    _floatArray = NULL;
                    _floatArrayCount = 0;
                }
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
        }
        
        if( EQSTR(elementName, kTag_bind_shape_matrix) )
        {
            iskin->_bindShapeMatrix = *(GLKMatrix4 *)_floatArray;
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
                    inode->_incomingSpec = NCSRoationX;
                else if( EQSTR(sid, kValue_sid_rotationY) )
                    inode->_incomingSpec = NCSRoationY;
                else
                    inode->_incomingSpec = NCSRoationZ;
                return;                    
            }
            
            if( EQSTR(elementName, kTag_skeleton) )
            {
                SET(kColStateCaptureText);
                return;
            }
            
            if( EQSTR(elementName, kTag_instance_controller) )
            {
                IncomingNode * inode = [incnt->_nodeStack lastObject];
                inode->_skinName = [(NSString *)attributeDict[kAttr_url] substringFromIndex:1];
                return;
            }
            
            if( EQSTR(elementName, kTag_instance_geometry) )
            {
                IncomingNode * inode = [incnt->_nodeStack lastObject];
                inode->_geometryName = [(NSString *)attributeDict[kAttr_url] substringFromIndex:1];
            }            
        }
        
        if( EQSTR(elementName, kTag_node) )
        {
            IncomingNode * inode = [IncomingNode new];
            inode->_name = attributeDict[kAttr_name];
            inode->_id   = attributeDict[kAttr_id];
            inode->_sid  = attributeDict[kAttr_sid];
            inode->_type = attributeDict[kAttr_type];
            
            IncomingNode * parent = [incnt->_nodeStack lastObject];
            if( parent )
                [parent addChild:inode];
            else
                incnt->_tree[inode->_id] = inode;
            [incnt->_nodeStack addObject:inode];
            
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
                inode->_transform = *(GLKMatrix4 *)_floatArray;
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
                if( inode->_incomingSpec == NCSRoationX )
                    inode->_rotationX = *(GLKVector3 *)_floatArray;
                else if( inode->_incomingSpec == NCSRoationY )
                    inode->_rotationY = *(GLKVector3 *)_floatArray;
                else
                    inode->_rotationZ = *(GLKVector3 *)_floatArray;
                inode->_coordSpec |= inode->_incomingSpec;
                inode->_incomingSpec = 0;
                _floatArray = NULL;
                _floatArrayCount = 0;
                return;
            }
            
            if( EQSTR(elementName, kTag_skeleton) )
            {
                IncomingNode * inode = [incnt->_nodeStack lastObject];
                inode->_skeletonName = [_captureString substringFromIndex:1];
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
    _nodeTree = incnt->_tree;
    _incoming = nil;
    UNSET(kColStateVisualScene);
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
    
    if( CHECKANY(kColStateIntArray) )
    {
        if( _ushortString )
           [_ushortString appendString:string];
        else
            _ushortString = [NSMutableString stringWithString:string];
        return;
    }
    
    if( CHECKANY(kColStateInStringArray) )
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

    if( CHECKANY(kColStateInStringArray) )
    {
        UNSET(kColStateInStringArray);
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
    
    if( CHECKANY(kColStateUp) )
    {
        if( EQSTR(_captureString, @"Z_UP") )
            _up = 'z';
        UNSET(kColStateUp);
    }
}

-(void)flatten:(MeshGeometryBuffer *)b
{
    unsigned int elementSize = b->stride;
    float * newBuffer = malloc( sizeof(float) * b->numIndices *elementSize);
    float * p = newBuffer;
    float * old = b->data;
    unsigned int * idx = b->indexData;
    int i;
    for( int x = 0; x < b->numIndices; x++ )
    {
        i = *idx++ * elementSize;
        for( int e = 0; e < elementSize; e++ )
            *p++ = old[i + e];
    }
    free(b->data);
    b->data = newBuffer;
    b->numFloats = b->numIndices * elementSize;
    b->numElements = b->numIndices;
    free(b->indexData);
    b->indexData = NULL;
    b->numIndices = 0;
}

-(void)repackIndex:(MeshGeometryBuffer *)buffer
          meshData:(IncomingMeshData *) meshData
            offset:(unsigned int)offset
   primitiveStride:(unsigned int)primitiveStride
{
    unsigned short * primitives    = meshData->_triangleTag->_primitives;
    unsigned int     numPrimitives = meshData->_triangleTag->_numPrimitives;
    unsigned short * vectorCounts  = meshData->_triangleTag->_vectorCounts;
    
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
    
    buffer->indexData  = realloc(newIndexBuffer, sizeof(unsigned int) * newIBufferIdx);
    buffer->numIndices = newIBufferIdx;
}

-(void)simpleRepackIndex:(MeshGeometryBuffer *)buffer
                meshData:(IncomingMeshData *) meshData
                  offset:(unsigned int)offset
         primitiveStride:(unsigned int)primitiveStride
{
    unsigned short * primitives    = meshData->_triangleTag->_primitives;
    unsigned int     numPrimitives = meshData->_triangleTag->_numPrimitives;
    
    unsigned int     newIndexCount    = numPrimitives / primitiveStride;
    unsigned int *   newIndexBuffer   = malloc( sizeof(unsigned int) * newIndexCount);
                                               
    for( int i = 0; i < newIndexCount; i++ )
    {
        int value = primitives[ i * primitiveStride + offset];
        newIndexBuffer[i] = value;
    }
    
    buffer->indexData  = newIndexBuffer;
    buffer->numIndices = newIndexCount;
}

-(void)turnUp:(MeshGeometryBuffer *)bufferInfo
{
    float * buffer = bufferInfo->data;
    for( int i = 0; i < bufferInfo->numFloats; i += 3 )
    {
        float y = buffer[i+1];
        buffer[i+1] = buffer[i+2];
        buffer[i+2] = y;
    }
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

-(MeshScene *)finalAssembly
{
    static bool (^hasJointDecsendant)(IncomingNode *) = ^bool (IncomingNode *node) {
        if( EQSTR(node->_type, kValue_name_JOINT) )
            return true;

        if( !node->_children )
            return false;
        
        for( NSString * nodeName in node->_children )
        {
            if( hasJointDecsendant(node->_children[nodeName]) )
                return true;
        }
        return false;
    };

    MeshScene * scene = [MeshScene new];
    
    IncomingNode * armatureNode = nil;
    IncomingNode * meshNode = nil;
    
    for( NSString * nodeName in _nodeTree )
    {
        IncomingNode * node = _nodeTree[nodeName];
        if( node->_skeletonName || node->_geometryName || node->_skinName )
        {
            meshNode = node;
        }
        else if( hasJointDecsendant(node) )
        {
            armatureNode = node;
        }
    }
    
    static MeshSceneArmatureNode *  (^mapArmatures)(MeshSceneArmatureNode *, IncomingNode *) =
    ^MeshSceneArmatureNode * (MeshSceneArmatureNode * parent, IncomingNode *inode) {

        MeshSceneArmatureNode * msan = [MeshSceneArmatureNode new];
        msan->_parent = parent;
        msan->_transform = inode->_transform;
        msan->_name = inode->_id;
        
        if( inode->_children )
        {
            for( NSString * nodeName in inode->_children )
            {
                IncomingNode * ichild = inode->_children[nodeName];
                MeshSceneArmatureNode * child = mapArmatures(msan,ichild);
                [msan addChild:child name:nodeName];
            }
        }
        
        return msan;
    };

    if( armatureNode )
    {
        scene->_armatureTree = mapArmatures(nil,armatureNode);
        [scene calcMatricies];
    }
    
    static MeshSceneArmatureNode *  (^findJointWithName)(NSString *,MeshSceneArmatureNode *) = nil;
    
    findJointWithName = ^MeshSceneArmatureNode * (NSString *name,MeshSceneArmatureNode *node) {
        
        if( !node )
            node = scene->_armatureTree;
        
        if( EQSTR(name, node->_name) )
            return node;
        
        if( node->_children )
        {
            for( NSString * nodeName in node->_children )
            {
                MeshSceneArmatureNode * child = node->_children[nodeName];
                MeshSceneArmatureNode * retNode = findJointWithName(name,child);
                if( retNode )
                    return retNode;
            }
        }
        
        return nil;
    };
    
    static MeshGeometry *  (^getGeometry)(NSString *) = nil;
    
    getGeometry = ^MeshGeometry * (NSString *name) {
        IncomingMeshData * meshData      = _geometries[name];
        MeshGeometry     * sceneGeometry = [MeshGeometry new];
        
        NSString * srcName;
        int primitiveStride = 0;
        unsigned int primitivesOffset[kNumMeshSemanticKeys];
        
        for( int i = 0; i < meshData->_triangleTag->_nextInput; i++ )
        {
            srcName = meshData->_triangleTag->_source[i];
            IncomingVertexData * ivd = meshData->_vertexDict[srcName];
            if( ivd->_redirectTo )
                ivd = meshData->_vertexDict[ivd->_redirectTo];
            
            MeshSemanticKey key = meshData->_triangleTag->_semanticKey[i];
            
            primitivesOffset[key] = meshData->_triangleTag->_offsets[i];
            sceneGeometry->_buffers[key] = ivd->_meta;
            int thisOffset = primitivesOffset[key] + 1;
            if(  thisOffset > primitiveStride )
                primitiveStride = thisOffset;
        }
        
        unsigned short *vectorCounts = meshData->_triangleTag->_vectorCounts;
        bool allThrees = true;
        if( vectorCounts )
        {
            for( unsigned int vc = 0; vc < meshData->_triangleTag->_count; vc++ )
            {
                if( vectorCounts[vc] != 3 )
                {
                    allThrees = false;
                    break;
                }
            }
        }

        for( MeshSemanticKey key = MSKPosition; key < kNumMeshSemanticKeys; key++ )
        {
            MeshGeometryBuffer *buffer = sceneGeometry->_buffers + key;
            
            if( buffer->data )
            {
                if( allThrees )
                    [self simpleRepackIndex:buffer
                                   meshData:meshData
                                     offset:primitivesOffset[key]
                            primitiveStride:primitiveStride];
                else
                    [self repackIndex:buffer
                             meshData:meshData
                               offset:primitivesOffset[key]
                      primitiveStride:primitiveStride];
                
                if( key != MSKPosition )
                    [self flatten:buffer];
            }
        }
        
        if(meshData->_triangleTag->_primitives)
            free(meshData->_triangleTag->_primitives);
        if(meshData->_triangleTag->_vectorCounts)
            free(meshData->_triangleTag->_vectorCounts);

        if( _up == 'z' )
            [self turnUp:sceneGeometry->_buffers];
        
        return sceneGeometry;
    };
    
    MeshSceneMeshNode * sceneMeshNode = [MeshSceneMeshNode new];
    
    if( meshNode->_skinName )
    {
        MeshSkinning * sceneSkin = [MeshSkinning new];
        IncomingSkin * iskin = _skins[ meshNode->_skinName];
        
        sceneSkin->_bindShapeMatrix = iskin->_bindShapeMatrix;
        sceneSkin->_influencingJointCounts          = iskin->_weights->_vcounts;
        sceneSkin->_numInfluencingJointCounts       = iskin->_weights->_numVcounts;
        sceneSkin->_packedWeightIndices         = iskin->_weights->_weights;
        sceneSkin->_numPackedWeightIndicies      = iskin->_weights->_numWeights;
        
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
                GLKMatrix4 * mats = (GLKMatrix4 *)iss->_data;
                
                for( NSString * jointName in jointNameArray )
                {
                    MeshSceneArmatureNode * joint = findJointWithName(jointName,nil);
                    joint->_invBindMatrix = *mats;
                    mats++;
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
        
        sceneSkin->_geometry = getGeometry( iskin->_meshSource );
        sceneMeshNode->_skin = sceneSkin;
        
        [self applyBindMatrix:sceneSkin->_geometry->_buffers
                   bindMatrix:sceneSkin->_bindShapeMatrix];
    }
    else if( meshNode->_geometryName )
    {
        sceneMeshNode->_geometry = getGeometry( meshNode->_geometryName );
    }
    
    if( meshNode->_skeletonName )
    {
        sceneMeshNode->_skeleton = findJointWithName( meshNode->_skeletonName, nil );
    }
    
    scene->_mesh = sceneMeshNode;
    
    if( [_animations count] )
    {
        for( NSString * namePath in _animations )
        {
            NSArray * parts = [namePath componentsSeparatedByString:@"/"];
            
            MeshAnimation * sceneAnim = _animations[namePath];
            sceneAnim->_target = findJointWithName(parts[0],nil);
            sceneAnim->_property = parts[1];
            [scene->_animations addObject:sceneAnim];
        }
    }
    
    return scene;
}
@end

@implementation ColladaParser

+(MeshScene *)parse:(NSString *)fileName
{
    ColladaParserImpl * cParser = [[ColladaParserImpl alloc] init];
    
    NSString * path = [[NSBundle mainBundle] pathForResource:[fileName stringByDeletingPathExtension]
                                                      ofType:[fileName pathExtension]];    
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    NSXMLParser * parser = [[NSXMLParser alloc] initWithData:data];
    [parser setDelegate:cParser];
    bool success = [parser parse]; 
    if( success )
    {
        MeshScene * scene = [cParser finalAssembly];
        return scene;
    }
    return nil;
}

@end