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
#import "ColladaParserInternals.h"

#import "Log.h"

#define CULL_NULL_ANIMATIONS 1

#define SET(f)      _state |= f
#define UNSET(f)    _state &= ~f
#define CHECK(f)    ((_state & f) == f)

#define EQMAT4(a,b) ( memcmp(a.m,b.m,sizeof(a.m)) == 0 )

static NSArray * cleanAndSeparateString( NSString * str )
{
    NSError *error = NULL;    
    NSRegularExpression * regex = [[NSRegularExpression alloc] initWithPattern:@"[^\\S]+"
                                                                       options:NSRegularExpressionAllowCommentsAndWhitespace
                                                                         error:&error];

    str = [str stringByTrimmingCharactersInSet:
           [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    str = [regex stringByReplacingMatchesInString:str options:0 range:(NSRange){0,[str length]} withTemplate:@" "];

    NSArray * arr =  [str componentsSeparatedByString:@" "];
    
    return  arr;
}

static float * parseFloats(NSString * str, int * numFloats, ColladaParserImpl * pool)
{
    NSArray * burp = cleanAndSeparateString(str);
    unsigned long count = [burp count];
    float * p = [pool malloc:sizeof(float)*count];
//   TGLog(LLShitsOnFire, @"malloc: %p",p);
    *numFloats = (int)count;
    float * buffer = p;
    for( NSString * f in burp )
        *p++ = [f floatValue];
    return buffer;
}

static float * copyFloats(float *original, int numFloats)
{
    float * p = malloc(sizeof(float)*numFloats);
    memcpy(p,original,sizeof(float)*numFloats);
    return p;
}

static unsigned short * parseUShorts(NSString * str, int * numUShorts, ColladaParserImpl * pool)
{
    NSArray * burp = cleanAndSeparateString(str);
    unsigned long count = [burp count];
    unsigned short * p = [pool malloc:sizeof(unsigned short)*count];
    *numUShorts = (int)count;
    unsigned short * buffer = p;
    for( NSString * f in burp )
        *p++ = (unsigned short)[f intValue];
    return buffer;
}

static NSArray * parseStringArray( NSString * str )
{
    return cleanAndSeparateString(str);
}

static int scanInt(NSString * str)
{
    if( !str )
        return -1;
    
    NSScanner * scanner = [[NSScanner alloc] initWithString:str];
    int i;
    [scanner scanInt:&i];
    return i;
}


//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingAnimation @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

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
    TGLog(LLObjLifetime, @"%@ released",self);
}
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@ IncomingVertexData  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@implementation IncomingSourceTag
- (void)dealloc
{
    TGLog(LLObjLifetime, @"%@ released",self);
}
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingMeshData @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

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

- (void)dealloc
{
    TGLog(LLObjLifetime, @"%@ released",self);
}
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingSkinSource @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@implementation IncomingSkinSource
- (void)dealloc
{
    if( _matrices )
        free(_matrices);
    if( _weights )
        free(_weights);
    
    TGLog(LLObjLifetime, @"%@ released",self);
}
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingWeights  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@implementation IncomingWeights

- (id)init
{
    self = [super init];
    if (self) {
        _sources = [NSMutableArray new];
    }
    return self;
}
- (void)dealloc
{
    TGLog(LLObjLifetime, @"%@ released",self);
}

@end
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingSkin @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

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
- (void)dealloc
{
    TGLog(LLObjLifetime, @"%@ released",self);
}

@end


//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingNodeTree @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@implementation IncomingNode
-(void)addChild:(IncomingNode *)child
{
    if( !_children )
        _children = [NSMutableDictionary new];
    _children[child->_id] = child;
}
- (void)dealloc
{
    TGLog(LLObjLifetime, @"%@ released",self);
}

@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  IncomingNodeTree @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

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

@implementation IncomingMaterial
- (void)dealloc
{
    TGLog(LLObjLifetime, @"%@ released",self);
}
@end

@implementation IncomingNewParam
@end

@implementation IncomingEffect
-(void)addNewParam:(NSString *)name value:(id)value
{
    if( !_newParams )
        _newParams = [NSMutableDictionary new];
    _newParams[name] = value;
}
@end

@implementation IncomingImage
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  ColladaParser @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#pragma mark CollalaParserImpl


@implementation ColladaParserImpl {
    
    id              _incoming;
    
    char            _up;
    
    ColladaTagState _state;
    
    NSMutableString * _floatString;
    float * _tempFloatArray;
    int _floatArrayCount;
    
    NSMutableString * _ushortString;
    unsigned short * _tempUShortArray;
    int _ushortArrayCount;
    
    NSMutableString * _stringArrayString;
    
    NSString * _captureString;
        
    NSMutableArray * _memPool;
}


-(id)init
{
    self = [super init];
    if( self )
    {
        _animDict = [NSMutableDictionary new];
        _geometries = [NSMutableDictionary new];
        _skins      = [NSMutableDictionary new];
        _nodes      = [NSMutableDictionary new];
        _materials  = [NSMutableDictionary new];
        _effects    = [NSMutableDictionary new];
        _materialBindings = [NSMutableDictionary new];
        _images = [NSMutableDictionary new];
        _up         = 'y';
        _memPool = [NSMutableArray new];
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
        if( EQSTR(elementName, kTag_source) )
        {
            SET(kColStateInSource);
            return;
        }
        
        if( CHECK(kColStateInSource) )
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
                ia->_animation->_keyFrames = copyFloats(_tempFloatArray, _floatArrayCount);
                ia->_animation->_numFrames = _floatArrayCount;
                
                _tempFloatArray = NULL;
                _floatArrayCount = 0;
            }
            if( EQSTR(ia->_paramType,kValue_type_float4x4) )
            {
                if( !ia->_paramName )
                    ia->_paramName = kValue_name_TRANSFORM;

                {
                    unsigned int numMatrices = _floatArrayCount / 16;
                    GLKMatrix4 * mats = (GLKMatrix4 *)copyFloats(_tempFloatArray, _floatArrayCount);
                    for( unsigned int i = 0; i < numMatrices; i++ )
                        mats[i] = GLKMatrix4Transpose(mats[i]);
                    ia->_animation->_transforms = mats;
                }
                _tempFloatArray = NULL;
                _floatArrayCount = 0;
            }
            
            UNSET(kColStateInSource);
        }
        
    }
}

-(void)assembleAnimation
{
    IncomingAnimation * ia = _incoming;
    _animDict[ia->_channelTarget] = ia->_animation;
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
                if( !ims->_redirectTo )
                    ims->_redirectTo = [NSMutableDictionary new];
                ims->_redirectTo[attributeDict[kAttr_semantic]] = [(NSString *)attributeDict[kAttr_source] substringFromIndex:1];
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
                    sem = gv_pos;
                else if( EQSTR(semantic, kValue_semantic_NORMAL) )
                    sem = gv_normal;
                else if( EQSTR(semantic, kValue_semantic_TEXCOORD) )
                    sem = gv_uv;
                else if( EQSTR(semantic, kValue_semantic_COLOR) )
                    sem = gv_acolor;
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
            if( EQSTR(elementName, kTag_vertices) )
            {
                IncomingSourceTag * ivd = meshData->_tempIncomingSourceTag;
                meshData->_sources[ivd->_id] = ivd;
                meshData->_tempIncomingSourceTag = nil;
                UNSET(kColStateInVertices);
            }
            return;
        }
        
        if( CHECK(kColStatePolyIndices) )
        {
            if( EQSTR(elementName, kTag_p) )
            {
                IncomingPolygonIndex * polyIndexTag = [meshData->_polygonTags lastObject];
                polyIndexTag->_primitives = _tempUShortArray;
                polyIndexTag->_numPrimitives = _ushortArrayCount;
                _ushortArrayCount = 0;
                _tempUShortArray = NULL;
                return;
            }
            
            if( EQSTR(elementName, kTag_vcount) )
            {
                IncomingPolygonIndex * itt = [meshData->_polygonTags lastObject];
                itt->_vectorCounts = _tempUShortArray;
                _ushortArrayCount = 0;
                _tempUShortArray = NULL;
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
                ivd->_bufferInfo.data = _tempFloatArray;
                _tempFloatArray = NULL;
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
                    
                    if( !iss->_paramName )
                        iss->_paramName = kValue_name_JOINT;
                }
                if( _tempFloatArray )
                {
                    if( EQSTR( iss->_paramType, kValue_type_float4x4 ) )
                    {
                        if( !iss->_paramName )
                            iss->_paramName = kValue_name_TRANSFORM;
                        
                        iss->_numMatrices = _floatArrayCount / 16;
                        iss->_matrices = malloc(sizeof(GLKMatrix4)*iss->_numMatrices);
                        for( int i = 0; i < iss->_numMatrices; i++ )
                            iss->_matrices[i] = GLKMatrix4Transpose(((GLKMatrix4*)_tempFloatArray)[i]);
                    }
                    else
                    {
                        if( !iss->_paramName )
                            iss->_paramName = kValue_name_WEIGHT;
                        
                        iss->_numWeights = _floatArrayCount;
                        iss->_weights = copyFloats(_tempFloatArray, _floatArrayCount);
                    }
                    _tempFloatArray = NULL;
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
                iskin->_weights->_vcounts = _tempUShortArray;
                iskin->_weights->_numVcounts = _ushortArrayCount;
                _tempUShortArray = NULL;
                _ushortArrayCount = 0;
                return;
            }
            
            if( EQSTR(elementName, kTag_v) )
            {
                iskin->_weights->_weights = _tempUShortArray;
                iskin->_weights->_numWeights = _ushortArrayCount;
                _tempUShortArray = NULL;
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
            iskin->_bindShapeMatrix = GLKMatrix4MakeWithArrayAndTranspose(_tempFloatArray);
            _tempFloatArray = NULL;
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
                inode->_transform = GLKMatrix4MakeWithArrayAndTranspose(_tempFloatArray);
//                inode->_transform = GLKMatrix4MakeWithArray(_floatArray);
                _tempFloatArray = NULL;
                _floatArrayCount = 0;
                return;
            }
            
            if( EQSTR(elementName, kTag_translate) )
            {
                IncomingNode * inode = [incnt->_nodeStack lastObject];
                inode->_coordSpec |= NCSLocation;
                inode->_location = *(GLKVector3 *)_tempFloatArray;
                _tempFloatArray = NULL;
                _floatArrayCount = 0;
                return;
            }

            if( EQSTR(elementName, kTag_scale) )
            {
                IncomingNode * inode = [incnt->_nodeStack lastObject];
                inode->_coordSpec |= NCSScale;
                inode->_scale = *(GLKVector3 *)_tempFloatArray;
                _tempFloatArray = NULL;
                _floatArrayCount = 0;
                return;
            }

            if( EQSTR(elementName, kTag_rotate) )
            {
                IncomingNode * inode = [incnt->_nodeStack lastObject];
                if( inode->_incomingSpec == NCSRotationX )
                    inode->_rotationX = *(GLKVector3 *)_tempFloatArray;
                else if( inode->_incomingSpec == NCSRotationY )
                    inode->_rotationY = *(GLKVector3 *)_tempFloatArray;
                else
                    inode->_rotationZ = *(GLKVector3 *)_tempFloatArray;
                inode->_coordSpec |= inode->_incomingSpec;
                inode->_incomingSpec = 0;
                _tempFloatArray = NULL;
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
                GLKVector4 color = *(GLKVector4 *)_tempFloatArray;
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
                _tempFloatArray = NULL;
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
        _tempFloatArray = parseFloats(_floatString, &_floatArrayCount, self);
        _floatString = nil;
        UNSET(kColStateFloatArray);
        
        if( EQSTR(elementName,kTag_float_array) )
            return;
    }
    
    if( CHECK(kColStateIntArray) )
    {
        _tempUShortArray = parseUShorts(_ushortString, &_ushortArrayCount, self);
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

-(void)parser:(NSXMLParser *)parser
parseErrorOccurred:(NSError *)parseError
{
    TGLog(LLShitsOnFire, @"%@ - %@ - %@",
          parseError,
          parseError.userInfo);
    exit(-1);
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

@implementation ColladaParserImpl (MemPool)

-(void *)malloc:(size_t)sz
{
    void * p = malloc(sz);
    NSData * nsd = [NSData dataWithBytesNoCopy:p length:sz freeWhenDone:YES];
    [_memPool addObject:nsd];
    return p;
}

@end
