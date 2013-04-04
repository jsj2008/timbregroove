//
//  GenericImport.m
//  TimbreGroove
//
//  Created by victor on 3/29/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "GenericImport.h"
#import "MeshSceneBuffer.h"
#import "ColladaParser.h"
#import "Texture.h"
#import "Light.h"
#import "State.h"

#import "Cube.h"
#import "Camera.h"

#define DEBUG_SKIN 1
#define DEBUG_SKIN_GEOMETRY 1

#ifdef DEBUG_SKIN
static void dumpMatrix(GLKMatrix4 m)
{
    printf("{ %+.4G, %+.4G, %+.4G, %+.4G, \n  %+.4G, %+.4G, %+.4G, %+.4G, \n  %+.4G, %+.4G, %+.4G, %+.4G, \n  %+.4G, %+.4G, %+.4G, %+.4G }",
           m.m00, m.m01, m.m02, m.m03,
           m.m10, m.m11, m.m12, m.m13,
           m.m20, m.m21, m.m22, m.m23,
           m.m30, m.m31, m.m32, m.m33 );
    
}
#endif

@interface VisibleBone : Generic {
@public
    GLKMatrix4 _transform;
    GLKVector3 _vec3;
    MeshSceneArmatureNode * _node;
}
@end
@implementation VisibleBone

-(id)wireUp
{
    [super wireUp];
    self.scaleXYZ = 0.4;
    self.disableStandarParameters = true;
    return self;
}

-(void)createBuffer
{
    MeshBuffer * mb = [Cube cubeWithWidth:0.6
                            andIndicesIntoNames:@[@(gv_pos)]
                                       andDoUVs:false
                             andDoNormals:false];

    [self addBuffer:mb];
}

@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@implementation GenericImport {
    MeshScene * _scene;
    MeshBuffer * _mb;
}

- (id)init
{
    self = [super init];
    if (self) {
        _bufferDrawType = GL_TRIANGLES;
    }
    return self;
}

-(id)wireUp
{
    _scene        = [ColladaParser parse:_colladaFile];
    self.color    = (GLKVector4){ 1, 0.2, 0.7, 0.4};
    self.position = (GLKVector3){ 0, -0.5, 0 };
//    self.rotation = (GLKVector3){ -GLKMathDegreesToRadians(90), 0, 0 };

#ifdef DEBUG_SKIN
    
    TGLogp(LLMeshImporter, @"// Imported COLLADA: %@",_colladaFile);
    
    NSString * baseName = [_colladaFile stringByDeletingPathExtension];
    
    MeshSkinning * skin = _scene->_mesh->_skin;
    if( skin )
    {
        TGLogp(LLMeshImporter, @"GLKMatrix4 %@_bindShapeMatrix = (GLKMatrix4)",baseName);
        dumpMatrix(skin->_bindShapeMatrix); printf(";\n");
        TGLogp(LLMeshImporter, @"float %@_weights[] = ",baseName);
       [skin debugDump];
    }
    
    if( _scene->_animations )
    {
        for( MeshAnimation * animation in _scene->_animations )
        {
            TGLogp(LLMeshImporter,@"GLKMatrix4 %@_%@_animationFrames[] = { ", baseName, animation->_target->_name);

            for( int i = 0; i < animation->_numFrames; i++ )
            {
                TGLogp(LLMeshImporter,@"\n// Frame[%d] at %fms ", i, animation->_keyFrames[i]);
                dumpMatrix(animation->_transforms[i]); printf(",\n");
            }
            TGLogp(LLMeshImporter,@"}; // end %@_%@_animationFrames", baseName, animation->_target->_name);
            
        };
    }
    
    static void (^dumpBones)(id,MeshSceneArmatureNode *) = nil;
    
    dumpBones = ^(id key, MeshSceneArmatureNode * node) {

        NSString * parentName = node->_parent ? node->_parent->_name : @"none";
        GLKVector4 vec4 = GLKMatrix4GetRow(node->_world, 3);
        TGLogp(LLMeshImporter, @"\n//-------------\"%@\" joint at {%.4f, %.4f, %.4f} parent: %@\n",
               node->_name, vec4.x, vec4.y, vec4.z, parentName );
        TGLogp(LLMeshImporter, @"GLKMatrix4 %@_%@_transform = (GLKMatrix4)",baseName, node->_name);
        dumpMatrix(node->_transform);
        TGLogp(LLMeshImporter, @";\n\nGLKMatrix4 %@_%@_world = (GLKMatrix4)",baseName, node->_name);
        dumpMatrix(node->_world);
        TGLogp(LLMeshImporter, @";\n\nGLKMatrix4 %@_%@_invBindPose = (GLKMatrix4)",baseName, node->_name);
        dumpMatrix(node->_invBindPoseMatrix);
        TGLogp(LLMeshImporter, @";\n");
        if( node->_children )
            [node->_children each:dumpBones];
    };
    
    dumpBones(nil, _scene->_armatureTree);
    
#endif
    
    [self showArmatures];
    
    return [super wireUp];
}

-(void)showArmatures
{
    if( _scene->_armatureTree )
    {
        static GLKVector4 colors[] = {
            { 1, 0, 0, 0.5 },
            { 0, 1, 0, 0.5 },
            { 0, 1, 1, 0.5 },
            { 1, 0, 1, 0.5 }
            };
        
        __block int nextColor = 0;
        
        static void (^createBones)(MeshSceneArmatureNode *) = nil;
        
        createBones = ^(MeshSceneArmatureNode * node) {
            VisibleBone * vb = [[VisibleBone alloc] init];
            vb->_node = node;
            vb->_transform = node->_world;
            GLKVector4 vec4 = GLKMatrix4GetRow(node->_world, 3);
            vb.position = *(GLKVector3 *)&vec4;
            vb.color = colors[nextColor];
            nextColor = ++nextColor % 4;
            [self appendChild:[vb wireUp]];
        };
        
        if( _scene->_animations )
        {
            [_scene->_animations each:^(MeshAnimation * animation) {
                createBones((MeshSceneArmatureNode *)animation->_target);
            }];
        }
        else
        {
            [_scene->_mesh->_skin->_influencingJoints each:createBones];
        }
    }
}

-(void)setColladaFile:(NSString *)colladaFile
{
    _colladaFile = colladaFile;
}

-(void)setDrawType:(NSString *)drawType
{
    if([drawType caseInsensitiveCompare:@"triangles"] == NSOrderedSame)
        _bufferDrawType = GL_TRIANGLES;
    else if([drawType caseInsensitiveCompare:@"triangle_strip"] == NSOrderedSame)
        _bufferDrawType = GL_TRIANGLE_STRIP;
}

-(void)releaseScene
{
    _scene = nil;
}

-(void)configureLightingxx
{
    if( !self.light )
        self.light = [Light new]; // defaults are good
    float subColor = 0;
    self.light.ambientColor = (GLKVector4){subColor, subColor, 1.0, 1.0};
    
    GLKVector3 lDir = self.light.direction;
    GLKMatrix4 mx = GLKMatrix4MakeTranslation( lDir.x, lDir.y, lDir.z );
    self.light.direction = GLKMatrix4MultiplyVector3(mx,(GLKVector3){-1, 0, -1});
}

-(void)createTexture
{
    self.texture = [[Texture alloc] initWithFileName:@"numText.png"];
}


-(void)createBuffer
{
    static GenericVariables indexIntoNamesMap[kNumMeshSemanticKeys] = {
        gv_pos,         // MSKPosition
        gv_normal,      // MSKNormal
        gv_uv,          // MSKUV
        gv_acolor,      // MSKColor
        gv_boneIndex,   // MSKBoneIndex,
        gv_boneWeights, // MSKBoneWeights,

    };
    MeshGeometry * geometry = [_scene getGeometry:nil];

    MeshGeometryBuffer * b = geometry->_buffers;

    // FIXME: all normals are broken
    b[MSKNormal].data = NULL;
    
    for( MeshSemanticKey key = MSKPosition; key < kNumMeshSemanticKeys; key++ )
    {
        MeshGeometryBuffer * mgb = geometry->_buffers + key;
        if( mgb->data )
        {
            MeshSceneBuffer * msb = [[MeshSceneBuffer alloc] initWithGeometryBuffer:mgb
                                                             andIndexIntoShaderName:indexIntoNamesMap[key]];
            if( key == MSKPosition )
            {
                _mb = msb;
                if( _scene->_mesh->_skin )
                    msb.usage = GL_DYNAMIC_DRAW;
                msb.drawType = _bufferDrawType;
            }
            else
            {
                msb.drawable = false;
            }
            
            [self addBuffer:msb];
        }
    }
    
#ifdef DEBUG_SKIN_GEOMETRY
    if( (TGGetLogLevel() & LLMeshImporter) != 0 )
    {
        NSString * baseName = [_colladaFile stringByDeletingPathExtension];
        
        static char * varname[] = {
            "gv_pos",
            "gv_normal",
            "gv_uv",
            "gv_acolor",
            "gv_boneIndex", 
            "gv_boneWeights"
        };
        
        for( int b = 0; b < 3; b ++ )
        {
            MeshGeometryBuffer * bufferInfo = geometry->_buffers + b;
            if( !bufferInfo->data )
                continue;
            
            TGLogp(LLMeshImporter, @"GLKVector3 %@_%s[%d] = {",
                   baseName,
                    varname[indexIntoNamesMap[b]],
                   bufferInfo->numFloats/bufferInfo->stride);

            float *p = bufferInfo->data;
            int count = bufferInfo->numFloats;
            for( int i = 0; i < count;  )
            {
                for( int r = 0; r < 3 && i < count; r++  )
                {
                    printf("{");
                    char * comma = "";
                    for( int s = 0; s < bufferInfo->stride; s++ )
                        { printf( "%s %+.3f ",comma, p[i++]); comma = ","; }
                    printf("}, ");
                }
                printf("\n");
            }
            printf("};\n");
            
            if( bufferInfo->indexData )
            {
                TGLogp(LLMeshImporter, @"unsigned int %@_%s_index[%d] = {",
                       baseName,
                       varname[indexIntoNamesMap[b]],
                       bufferInfo->numIndices );
                
                unsigned int *p = bufferInfo->indexData;
                int count = bufferInfo->numIndices;
                int i;
                for( i = 0; i < count;  )
                {
                    for( int r = 0; r < 3 && i < count; r++  )
                    {
                        printf(" ");
                        char * comma = "";
                        for( int s = 0; s < 3; s++ )
                        {
                            printf( "%s %d",comma,p[i++]);
                            comma = ",";
                        }
                        printf(", ");
                    }
                    printf("\n");
                }
                printf("};\n");
                
                
                TGLogp(LLMeshImporter, @"GLKVector3 %@_%s_flat[%d] = {",
                       baseName,
                       varname[indexIntoNamesMap[b]],
                       bufferInfo->numIndices );
                {
                    
                    MeshGeometryBuffer * b = bufferInfo;
                    unsigned int elementSize = b->stride;
                    float * old = b->data;
                    unsigned int * idx = b->indexData;
                    int i;
                    for( int x = 0; x < b->numIndices; x++ )
                    {
                        i = *idx++ * elementSize;
                        printf(" { ");
                        char *comma = "";
                        for( int e = 0; e < elementSize; e++ )
                        {
                            float f = old[i + e];
                            printf( "%s %+.3f", comma, f );
                            comma = ",";
                        }
                        printf(" },");
                        if( (x+1) % 3 == 0 )
                            printf("\n");
                    }
                    printf("};\n");
                }
            }
        }
    }
#endif
}

-(void)update:(NSTimeInterval)dt
{
    if ( _scene->_animations )
    {
        __block bool dirty = false;
        [_scene->_animations each:^(MeshAnimation * animation) {
            animation->_clock += dt;
            while( animation->_clock >= animation->_keyFrames[animation->_nextFrame] )
            {
                MeshSceneNode * node = animation->_target;
                
                node->_transform = animation->_transforms[animation->_nextFrame];

                ++animation->_nextFrame;
                if( animation->_nextFrame == animation->_numFrames )
                {
                    animation->_clock = 0;
                    animation->_nextFrame = 0;
                }
                dirty = true;
            }
        }];
        
        if( dirty )
        {
       //     [_scene calcAnimationMatricies];

            [self.children each:^(VisibleBone *vb) {
                MeshSceneArmatureNode * node = vb->_node;
                GLKVector4 vec4 = GLKMatrix4GetRow(node->_world, 3);
                vb.position = *(GLKVector3 *)&vec4;
#if 0
                GLKVector4 tvec4 = GLKMatrix4GetRow(node->_transform, 3);
                TGLog(LLMeshImporter, @"world: { %.3f, %.3f, %.3f }  trans:  { %.3f, %.3f, %.3f }",
                      vec4.x, vec4.y, vec4.z, tvec4.x, tvec4.y, tvec4.z );
#endif
            }];
            
            MeshSkinning * skin = _scene->_mesh->_skin;
            
            if( skin )
            {
                MeshGeometry * geometry = [_scene getGeometry:nil];
                MeshGeometryBuffer * b = geometry->_buffers;
                float * p = malloc( sizeof(float) * b->numFloats );
                [skin influence:b dest:p];
                [_mb setData:p];
                free(p);
            }
        }
    }
}
-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    [super render:w h:h];

}
@end
