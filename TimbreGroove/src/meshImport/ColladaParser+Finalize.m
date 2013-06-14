//
//  ColladaParser+Finalize.m
//  TimbreGroove
//
//  Created by victor on 4/29/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "ColladaParser.h"
#import "ColladaParserInternals.h"
#import "MeshScene.h"
#import "Material.h"

extern NSString * const kValue_semantic_JOINT;
extern NSString * const kValue_semantic_NORMAL;
extern NSString * const kValue_semantic_POSITION;
extern NSString * const kValue_semantic_TEXCOORD;
extern NSString * const kValue_semantic_COLOR;
extern NSString * const kValue_semantic_WEIGHT;
extern NSString * const kTag_phong;
extern NSString * const kTag_sampler2D;
extern NSString * const kTag_surface;
extern NSString * const kValue_name_JOINT;
extern NSString * const kValue_name_TRANSFORM;
extern NSString * const kValue_name_WEIGHT;

@implementation ColladaParserImpl (Finalize)

-(void)removeIndexForSemantic:(IncomingMeshData *)imd
                          key:(MeshSemanticKey)key
{
    for( IncomingPolygonIndex * ipi in imd->_polygonTags)
    {
        int keyIndex = -1;
        int totalStride = 0;
        
        for( int i = 0; i < ipi->_nextInput; i++ )
        {
            if( ipi->_semanticKey[i] == key )
            {
                keyIndex = i;
            }
            ++totalStride;
        }
        
        if( keyIndex == -1 )
            continue;
        
        int keyOffset = ipi->_offsets[keyIndex];
        
        unsigned int numShortsToRemove = ipi->_count * 3;
        unsigned int newCount = ipi->_numPrimitives - numShortsToRemove;
        unsigned short int * newPrimitives = [self malloc:sizeof(unsigned short int) * newCount];
        unsigned short int * target = newPrimitives;
        unsigned short int * src = ipi->_primitives;
        for( int n = 0; n < ipi->_count; n++ )
        {
            for( int t = 0; t < 3; t++ )
            {
                for( int s = 0; s < totalStride; s++ )
                {
                    if( s != keyOffset )
                        *target++ = *src;
                    ++src;
                }
            }
        }

        ipi->_primitives = newPrimitives;
        ipi->_numPrimitives = newCount;
        
        for( int q = keyIndex; q < ipi->_nextInput-1; q++ )
        {
            ipi->_semanticKey[q] = ipi->_semanticKey[q+1];
        }
        --ipi->_nextInput;
        [ipi->_sourceURL removeObjectAtIndex:keyIndex];
    }
}

-(NSArray *)buildOpenGlBuffer:(IncomingMeshData *)imd
            influencingJoints:(NSArray *)influencingJoints
                 incomingSkin:(IncomingSkin *)iskin
{
    
    if( !imd->_honorUVs )
       [self removeIndexForSemantic:imd key:gv_uv];
    
    
    NSMutableArray * geometries = [NSMutableArray new];
    
    float * flattenedJointWeights = NULL;
    unsigned short * flattenedJointIndecies = NULL;
    int numInfluencingJoints = 0;
    bool sourceIsBound = false;
    
    // A mesh in the Collada file can have several <triangle*>
    // tags - each representing a shape, typically with a
    // unique texture/material that are all draw from the
    // same vertext <source>
    
    // *there might also be <polylist> tags but this function
    // assumes the data has been triangulated at some point
    
    // The skinning information is shared between all shapes
    // so we massage it before digging into the <triangle>s
    if( influencingJoints )
    {
        // actually this is the number of POTENTIALLY influencing joints
        numInfluencingJoints = [influencingJoints count];
        
#define JOINT_STRIDE 4
        
        int  jointWOffset;
        int  weightFOffset;
        
        for( int i = 0; i < iskin->_weights->_nextInput; i++ )
        {
            SkinSemanticKey sskey = iskin->_weights->_semanticKey[i];
            if( sskey == SSKJoint )
                jointWOffset = iskin->_weights->_offsets[i];
            else
                weightFOffset = iskin->_weights->_offsets[i];
        }
        
        float *          weights     = iskin->_weightSource->_weights;
        //int            numWeights  = iskin->_weightSource->_count;
        
        unsigned short * influencingJointCounts     = iskin->_weights->_vcounts;
        int              numInfluencingJointCounts  = iskin->_weights->_numVcounts;
        unsigned short * packedWeightIndices        = iskin->_weights->_weights;
        //int            numPackedWeightIndicies    = iskin->_weights->_numWeights;
        
        // we need random access to the weight/joint information to
        // access it via the vertex index in the <triangle><p> we are
        // parsing below. The native format is packed such that non-
        // influencing joints do not appear. We will unpack to fixed
        // length fields (len:=number of possibly influencing joints)
        // and pad with 0 for irrelevant joints
        size_t szf = sizeof(float) * JOINT_STRIDE * numInfluencingJointCounts;
        flattenedJointWeights = malloc( szf );
        memset(flattenedJointWeights,0,szf);
        size_t szi = sizeof(unsigned short) * JOINT_STRIDE * numInfluencingJointCounts;
        flattenedJointIndecies = malloc( szi );
        memset(flattenedJointIndecies, 0, szi );
        float * p  = flattenedJointWeights;
        unsigned short * pi = flattenedJointIndecies;
        unsigned int currPos = 0;
        
        for( int i = 0; i < numInfluencingJointCounts; i++ )
        {
            // this is the actual number of joints applied to this vertex
            int numberOfJointsApplied = influencingJointCounts[i];
#if DEBUG
            if( numberOfJointsApplied > JOINT_STRIDE )
            {
                TGLog(LLShitsOnFire, @"The maximum number of weight influences is %d. You've got: %d", JOINT_STRIDE, numberOfJointsApplied);
                // exit(-1);
            }
#endif
            unsigned int jointIndex;
            unsigned int weightIndex;
            for( int j = 0; j < numberOfJointsApplied; j++ )
            {
                jointIndex  = packedWeightIndices[ currPos + jointWOffset];
                weightIndex = packedWeightIndices[ currPos + weightFOffset];
                
                currPos += 2;
                
                if( j < JOINT_STRIDE )
                {
                    *pi++ = jointIndex;
                    *p++  = weights[weightIndex];
                }
            }
            
            if( numberOfJointsApplied < JOINT_STRIDE )
            {
                unsigned diff = JOINT_STRIDE - numberOfJointsApplied;
                p += diff;
                pi += diff;
            }
        }
        
        /*
        free(iskin->_weights->_vcounts);
        iskin->_weights->_vcounts = NULL;
        free(iskin->_weights->_weights);
        iskin->_weights->_weights = NULL;
         */
    }
    
    for( IncomingPolygonIndex * ipi in imd->_polygonTags)
    {
        IncomingSourceTag * isourceTags[kNumMeshSemanticKeys];
        memset(isourceTags, 0, sizeof(isourceTags));
        
        unsigned int primitivesOffset[kNumMeshSemanticKeys];
        unsigned int numVertices = ipi->_count * 3;
        unsigned int primitiveStride = 0;
        
        for( int i = 0; i < ipi->_nextInput; i++ )
        {
            // dig out the relevant source tags
            NSString * srcName = ipi->_sourceURL[i];
            IncomingSourceTag * ist = imd->_sources[srcName];
            MeshSemanticKey key;
            if( ist->_redirectTo )
            {
                for( NSString * semantic in ist->_redirectTo )
                {
                    IncomingSourceTag * redirectTag;
                    if( EQSTR(semantic, kValue_semantic_POSITION) )
                        key = gv_pos;
                    else if( EQSTR(semantic, kValue_semantic_NORMAL) )
                        key = gv_normal;
                    else if( EQSTR(semantic, kValue_semantic_COLOR) )
                        key = gv_acolor;
                    else if( EQSTR(semantic, kValue_semantic_TEXCOORD) )
                        key = gv_uv;
                    
                    redirectTag = imd->_sources[ ist->_redirectTo[semantic] ];
                    isourceTags[ key ] = redirectTag;
                    primitivesOffset[ key ] = ipi->_offsets[i];
                }
            }
            else
            {
                key = ipi->_semanticKey[i];
                isourceTags[ key ] = ist;
            }
            
            // calculate stride
            primitivesOffset[ key ] = ipi->_offsets[i];
            int thisOffset = primitivesOffset[key] + 1;
            if( thisOffset > primitiveStride )
                primitiveStride = thisOffset;
            
        }
        
        // calculate num floats of target buffer
        unsigned int numFloats = 0;
        for( int i = 0; i < kNumMeshSemanticKeys; i++ )
        {
            IncomingSourceTag * ist = isourceTags[i];
            if( ist )
                numFloats += numVertices * ist->_bufferInfo.stride;
        }
        
        if( iskin )
        {
            // JOINT_STRIDE influences + JOINT_STRIDE joint
            // indices per vertext
            numFloats += (JOINT_STRIDE + JOINT_STRIDE) * numVertices;
            
            // yea, it's a litle buried here but it's definitely
            // the most convient place to apply the BindShapeMatrix:
            if( !sourceIsBound )
            {
                IncomingSourceTag * ist = isourceTags[ gv_pos ];
                GLKVector3 * vectors = (GLKVector3 *)ist->_bufferInfo.data;
                for( int v = 0; v < ist->_bufferInfo.numElements; v++ )
                {
                    vectors[v] = GLKMatrix4MultiplyVector3(iskin->_bindShapeMatrix, vectors[v]);
                }
                sourceIsBound = true;
            }
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
            if( iskin )
            {
                index = primitives[ primitivesOffset[ gv_pos ] ] * 4;
                unsigned short * jindex  = flattenedJointIndecies + index;
                float * weights = flattenedJointWeights + index;
                for( int ji = 0; ji < JOINT_STRIDE; ji++ )
                    *p++ = *jindex++;
                for( int w = 0; w < JOINT_STRIDE; w++ )
                    *p++ = *weights++;
            }
            primitives += primitiveStride;
        }
        
        MeshGeometry * mg = [MeshGeometry new];
        mg->_name         = imd->_geometryName;
        mg->_materialName = ipi->_materialName;
        mg->_numVertices  = numVertices;
        mg->_buffer       = openGLBuffer;
        
        TGLog(LLMeshImporter, @"Imported mesh shape:%@ verts:%d mat:%@", mg->_name, numVertices, mg->_materialName);
        
        int strideCount = 0;
        for( int key = 0; key < kNumMeshSemanticKeys; key++ )
        {
            IncomingSourceTag * ist = isourceTags[key];
            if( !ist )
                continue;
            
            VertexStride * vs = &mg->_strides[ strideCount++ ];
            vs->glType = GL_FLOAT;
            vs->numSize = sizeof(float);
            vs->numbersPerElement = ist->_bufferInfo.stride;
            vs->indexIntoShaderNames = key;
            vs->location = -1;
            TGLog(LLMeshImporter, @"Includes %s buffer",
                  key == gv_pos      ? "pos" :
                  key == gv_uv       ? "UV"  :
                  key == gv_normal   ? "normals" :
                  "color");
        }
        
        if( iskin )
        {
            VertexStride * vs;
            
            vs = &mg->_strides[ strideCount++ ];
            vs->glType = GL_FLOAT;
            vs->numSize = sizeof(float);
            vs->numbersPerElement = 4;
            vs->indexIntoShaderNames = gv_boneIndex;
            vs->location = -1;
            
            vs = &mg->_strides[ strideCount++ ];
            vs->glType = GL_FLOAT;
            vs->numSize = sizeof(float);
            vs->numbersPerElement = 4;
            vs->indexIntoShaderNames = gv_boneWeights;
            vs->location = -1;
            TGLog(LLMeshImporter, @"Includes bones index/weight buffers");
            mg->_hasBones = true;
        }
        else
        {
            mg->_hasBones = false;
        }
        mg->_numStrides = strideCount;
        
        [geometries addObject:mg];
    }
    
    /*
    [imd->_sources each:^(id key, IncomingSourceTag * ist) {
        if( ist->_bufferInfo.data )
            free( ist->_bufferInfo.data );
    }];
     */
    
    if( flattenedJointWeights )
        free(flattenedJointWeights);
    if( flattenedJointIndecies )
        free(flattenedJointIndecies);
    
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
    
    scene->_allJoints = [[jointNodes mapReduce:^id(id key, MeshSceneNode *node) {
        if( node->_type == MSNT_Armature && !node->_parent )
            return node;
        return nil;
    }] allValues];
    
    if( scene->_allJoints )
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
            
            runtimeNode->_geometries = [self buildOpenGlBuffer:meshData influencingJoints:nil incomingSkin:nil];
        }
        else if( inode->_msnType == MSNT_SkinnedMesh )
        {
            IncomingSkin * iskin = _skins[ inode->_skinName];
            NSMutableArray * influencingJoints = [NSMutableArray new];
            
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
                    GLKMatrix4 * mats = iss->_matrices;
                    
                    for( NSString * jointName in jointNameArray )
                    {
                        MeshSceneArmatureNode * joint = findJointWithName(jointName,nil);
                        joint->_invBindMatrix = *mats++;
                    }
                }
                else if( EQSTR(iss->_paramName, kValue_name_WEIGHT) )
                {
                    iskin->_weightSource = iss;
                }
            }
            
            for( NSString * jointName in jointNameArray )
            {
                MeshSceneArmatureNode * joint = findJointWithName(jointName,nil);
                TGLog(LLMeshImporter, @"Imported joint: %@", jointName);
                [influencingJoints addObject:joint];
            }
            
            MeshSceneMeshNode * runtimeNode = meshNodes[inode->_id];
            runtimeNode->_influencingJoints = influencingJoints;
            runtimeNode->_geometries = [self buildOpenGlBuffer:_geometries[iskin->_meshSource]
                                             influencingJoints:influencingJoints
                                                  incomingSkin:iskin];
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
                    Texture          * t = nil;
                    NSString         * textureFileName = nil;
                    Material         * mm = [Material withColors:ie->_colors
                                                       shininess:ie->_shininess
                                                      doSpecular:EQSTR( ie->_type, kTag_phong )];
                    mm.name = ipi->_materialName;
                    
                    if( ie->_textureName )
                    {
                        mm.diffuse = (GLKVector4){ 1, 1, 1, 1 };
                        
                        IncomingNewParam * inp = ie->_newParams[ie->_textureName];
                        if( inp && EQSTR(inp->_tag, kTag_sampler2D) )
                        {
                            inp = ie->_newParams[ inp->_content ];
                            if( inp && EQSTR(inp->_tag, kTag_surface) )
                            {
                                IncomingImage * ii = _images[ inp->_content];
                                if( ii )
                                {
                                    textureFileName = [ii->_init_from lastPathComponent];
                                    t = [[Texture alloc] initWithFileName:textureFileName];
                                }
                            }
                        }
                        
                        if( textureFileName )
                        {
                            TGLog(LLShitsOnFire, @"Could not dig out a texture file name for %@", ie->_textureName);
                            exit(-1);
                        }
                        else
                        {
                            TGLog(LLMeshImporter, @"Imported texture %s for %@", textureFileName, inode->_id);
                        }
                    }
                    else
                    {
                        MaterialColors mc = mm.colors;
                        TGLog(LLMeshImporter, @"Material %@/%@ for %@ ",
                              ipi->_materialName, im->_effect, inode->_id);
                        TGLogp(LLMeshImporter,
                               @"   { .ambient = %@, .diffuse = %@,\n    .specular = %@, .emission = %@ }",
                               stringFromColor(mc.ambient),  stringFromColor(mc.diffuse),
                               stringFromColor(mc.specular), stringFromColor(mc.emission));
                    }
                    if( !materials )
                        materials = [NSMutableDictionary new];
                    NSArray * mats = t ? @[mm,t] : @[mm];
                    materials[ipi->_materialName] = mats;
                }
            }
            
            MeshSceneMeshNode * runtimeNode = meshNodes[inode->_id];
            runtimeNode->_materials = materials;
        }
        
        if( inode->_children )
            [inode->_children each:passFive];
    };
    
    [_nodes each:passFive];
    
    if( [_animDict count] )
    {
        NSMutableArray * sceneAnimations = [NSMutableArray new];
        
        for( NSString * namePath in _animDict )
        {
            NSArray * parts = [namePath componentsSeparatedByString:@"/"];
            
            MeshAnimation * sceneAnim = _animDict[namePath];
            
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
                    TGLog(LLMeshImporter, @"Imported animation for %@/%@", parts[0],parts[1]);
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
