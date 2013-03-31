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

@interface VisibleBone : Generic {
@public
    GLKMatrix4 _transform;
    GLKVector3 _vec3;
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

-(GLKMatrix4)modelViewxxx
{
 //   GLKMatrix4 mx = [super modelView];
 //   return GLKMatrix4Multiply(_transform,mx);
    
    _vec3 = GLKMatrix4MultiplyVector3WithTranslation(_transform, (GLKVector3){0,0,0});
    
    return _transform;
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

@implementation GenericImport {
    MeshScene * _scene;
}

-(id)wireUp
{
    [super wireUp];
    
    Camera * camera = self.camera;
    GLKVector3 pos = camera.position;
    pos.z -= 2.0;
    camera.position = pos;
    
    return self;
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
    _scene = [ColladaParser parse:colladaFile];
    [self showArmatures];
    self.color = (GLKVector4){ 1, 0.2, 0.4, 0.1};
    self.position = (GLKVector3){ 0, 1.2, 0 };
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

// FIXME: hack to undo indexing, why is this needed?
-(void)flatten:(MeshGeometryBuffer *)b
{
    float * newBuffer = malloc( sizeof(float) * b->numIndices * 3);
    float * p = newBuffer;
    float * old = b->data;
    unsigned int * idx = b->indexData;
    
    for( int x = 0; x < b->numIndices; x++ )
    {
        int i = *idx++ * 3;
        *p++ = old[i];
        *p++ = old[i+1];
        *p++ = old[i+2];
    }
    free(b->data);
    b->data = newBuffer;
    b->numFloats = b->numIndices * 3;
    b->numElements = b->numIndices;
}

-(void)createBuffer
{
    static GenericVariables indexIntoNamesMap[kNumMeshSemanticKeys] = {
        gv_pos,    // MSKPosition
        gv_normal, // MSKNormal
        gv_uv,     // MSKUV
        gv_acolor  // MSKColor
    };
    MeshGeometry * geometry = [_scene getGeometry:nil];

    MeshGeometryBuffer * b = geometry->_buffers;

    // FIXME: all normals are broken
    b[MSKNormal].data = NULL;
    [self flatten:b];
    
    for( MeshSemanticKey key = MSKPosition; key < kNumMeshSemanticKeys; key++ )
    {
        MeshGeometryBuffer * mgb = geometry->_buffers + key;
        if( mgb->data )
        {
            // FIXME: disabling all indexing. Ouch.
            MeshGeometryBuffer mcopy = *mgb;
            mcopy.indexData = NULL;

            MeshSceneBuffer * msb = [[MeshSceneBuffer alloc] initWithGeometryBuffer:&mcopy
                                                             andIndexIntoShaderName:indexIntoNamesMap[key]];
            [self addBuffer:msb];
            if( key != MSKPosition )
                msb.drawable = false;
        }
    }
    
#if 0
    if( (TGGetLogLevel() & LLMeshImporter) != 0 )
    {
        static char * varname[] = {
            "gv_acolor",
            "gv_normal",
            "gv_pos",
            "gv_uv" };
        
        for( int b = 0; b < 3; b ++ )
        {
            MeshGeometryBuffer * bufferInfo = geometry->_buffers + b;
            if( !bufferInfo->data )
                continue;
            
            TGLogp(LLMeshImporter, @"Dumping buffer for: %s", varname[indexIntoNamesMap[b]]);
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
                TGLogp(LLMeshImporter, @"Index");
                unsigned int *p = bufferInfo->indexData;
                int count = bufferInfo->numIndices;
                for( int i = 0; i < count;  )
                {
                    for( int r = 0; r < 3 && i < count; r++  )
                    {
                        printf("{");
                        for( int s = 0; s < bufferInfo->stride; s++ )
                            printf( " %d ",p[i++]);
                        printf("} ");
                    }
                    printf("\n");
                }
            }
        }
    }
#endif
    
    [self releaseScene];
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    BlendState * bs = [BlendState enable:true];
    
    [super render:w h:h];

    [bs restore];
}
@end
