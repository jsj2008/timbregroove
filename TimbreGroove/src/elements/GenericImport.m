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


static void dumpMatrix(GLKMatrix4 m)
{
    printf("\n{ %+.4f, %+.4f, %+.4f, %+.4f, \n  %+.4f, %+.4f, %+.4f, %+.4f, \n  %+.4f, %+.4f, %+.4f, %+.4f, \n  %+.4f, %+.4f, %+.4f, %+.4f }\n",
            m.m[0], m.m[1], m.m[2], m.m[3],
           m.m[4], m.m[5], m.m[6], m.m[7],
           m.m[8], m.m[9], m.m[10], m.m[11],
           m.m[12], m.m[13], m.m[14], m.m[15] );
}

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
    _scene = [ColladaParser parse:_colladaFile];
    [self showArmatures];
    self.color = (GLKVector4){ 1, 0.2, 0.7, 0.4};

#if 1
    if( _scene->_animations )
        [_scene->_animations each:^(MeshAnimation * animation) {
            TGLog(LLMeshImporter,@"Frames for: %@", animation->_target->_name);
            for( int i = 0; i < animation->_numFrames; i++ )
            {
                TGLog(LLMeshImporter,@"Frame[%d] : %f ", i, animation->_keyFrames[i]);
                dumpMatrix(animation->_transforms[i]);
            }
        }];
#endif
    
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
        
        static void (^createBones)(id,MeshSceneArmatureNode *) = nil;
        
        createBones = ^(id key, MeshSceneArmatureNode * node) {
            VisibleBone * vb = [[VisibleBone alloc] init];
            vb->_node = node;
            vb->_transform = node->_world;
            GLKVector4 vec4 = GLKMatrix4GetRow(node->_world, 3);
            vb.position = *(GLKVector3 *)&vec4;
            TGLog(LLMeshImporter, @"%@ bond node at {%.4f, %.4f, %.4f}", node->_name, vec4.x, vec4.y, vec4.z );
            vb.color = colors[nextColor];
            nextColor = ++nextColor % 4;
            [self appendChild:[vb wireUp]];
            if( node->_children )
               [node->_children each:createBones];
        };
        
        createBones(nil, _scene->_armatureTree);
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
    
#if 0
    if( (TGGetLogLevel() & LLMeshImporter) != 0 )
    {
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
            
            TGLogp(LLMeshImporter, @"Dumping buffer for: %s (%d/%d)",
                    varname[indexIntoNamesMap[b]],
                   bufferInfo->numFloats/bufferInfo->stride,
                    bufferInfo->numFloats);
            float *p = bufferInfo->data;
            int count = bufferInfo->numFloats;
            for( int i = 0; i < count;  )
            {
                for( int r = 0; r < 3 && i < count; r++  )
                {
                    printf("{");
                    for( int s = 0; s < bufferInfo->stride; s++ )
                        printf( " %+.3f ",p[i++]);
                    printf("} ");
                }
                printf("\n");
            }
            
            if( bufferInfo->indexData )
            {
                TGLogp(LLMeshImporter, @"Index (%d/%d)",
                       bufferInfo->numIndices/3,
                       bufferInfo->numIndices);
                
                unsigned int *p = bufferInfo->indexData;
                int count = bufferInfo->numIndices;
                int i;
                for( i = 0; i < count;  )
                {
                    for( int r = 0; r < 3 && i < count; r++  )
                    {
                        printf("{");
                        for( int s = 0; s < 3; s++ )
                            printf( " %d ",p[i++]);
                        printf("} ");
                    }
                    printf("\n");
                }
                
                
                TGLogp(LLMeshImporter, @"Flattened geometry");
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
                        for( int e = 0; e < elementSize; e++ )
                        {
                            float f = old[i + e];
                            printf( " %+.3f", f );
                        }
                        printf(" }");
                        if( (x+1) % 3 == 0 )
                            printf("\n");
                    }
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
            if( animation->_clock >= animation->_keyFrames[animation->_nextFrame] )
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
            [_scene calcMatricies];

            [self.children each:^(VisibleBone *vb) {
                GLKVector4 vec4 = GLKMatrix4GetRow(vb->_node->_world, 3);
                vb.position = *(GLKVector3 *)&vec4;
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
