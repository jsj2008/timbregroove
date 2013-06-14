//
//  GenericImport.m
//  TimbreGroove
//
//  Created by victor on 3/29/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#define SKIP_MESH_IMPORT_DECLS

#import "MeshImportPainter.h"
#import "MeshScene.h"
#import "PainterCamera.h"
#import "ColladaParser.h"
#import "Material.h"
#import "Light.h"
#import "State.h"
#import "Parameter.h"
#import "Names.h"
#import "Joints.h"
#import "Cube.h"

#import "Scene.h"
#import "TriggerMap.h"

NSString * const kImportedAnimation = @"_imported";

@interface MeshImportPainter (Dump)
-(void)dumpMetrics;
@end

@interface MeshNodePainter : Painter
@property (nonatomic) bool disabled;
@end

@implementation MeshNodePainter {
@public
    MeshSceneMeshNode * _node;
    NSString *          _name;
    NSMutableArray *    _jointFeatures;
}

-(id)init
{
    TGLog(LLShitsOnFire, @"no init without node please. thank you");
    exit(-1);
}

-(id)initWithNode:(MeshSceneMeshNode *)node
{
    self = [super init];
    if( self )
    {
        _node = node;
        _name = node->_name;
    }
    return self;
}

-(void)setDisabled:(bool)disabled
{
    [_jointFeatures each:^(Joints * j) { j.disabled = disabled; }];
}

-(id)wireUp
{
    [super wireUp];
    
    _node = nil; 
    return self;
}

-(void)createBuffer
{
    int count = [_node->_geometries count];
    for( MeshGeometry * geometry in  _node->_geometries )
    {
        NSMutableArray * shaderFeatures = [NSMutableArray new];
        
        if( geometry->_hasBones )
        {
            Joints * j = [Joints withArmatureNodes:_node->_influencingJoints];
            [shaderFeatures addObject:j];
            if( !_jointFeatures )
                _jointFeatures = [NSMutableArray new];
            [_jointFeatures addObject:j];
        }
        
        if( geometry->_materialName )
        {
            NSArray * importedMats = _node->_materials[ geometry->_materialName ];
            for( Material * material in importedMats)
                [shaderFeatures addObject:material];
        }
        
        MeshBuffer * mb = [[MeshBuffer alloc] init];
        [mb setData:geometry->_buffer
            strides:&geometry->_strides[0]
       countStrides:geometry->_numStrides
        numVertices:geometry->_numVertices
          indexData:NULL
         numIndices:0];
        //mb.drawType = GL_POINTS;
        
        if( count > 1 )
        {
            [self addShape:mb features:shaderFeatures];
        }
        else
        {
            [self addBuffer:mb];
            [shaderFeatures each:^(id sf) {
                [self addShaderFeature:sf];
            }];
        }
    }
    
}

@end
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@implementation MeshImportPainter {
    MeshScene * _scene;
    NSArray * _nodePainters;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.disableStandardParameters = true;
        _animations = [[AnimationDictionary alloc] init];
        [self makeLights];
    }
    return self;
}

-(id)wireUp
{
    _scene = [ColladaParser parse:_colladaFile];
    
    if( _scene->_animations )
        [_animations addClip:[Animation withAnimations:_scene->_animations name:kImportedAnimation]];
    
    [self buildNodePainters];
    [super wireUp];
    if( _runEmitter )
    {
        LogLevel logl = TGGetLogLevel();
        TGSetLogLevel(logl | LLMeshImporter);
        [_scene emit];
        TGSetLogLevel(logl);
    }

    if( _cameraZ )
    {
        GLKVector3 pos = self.camera.position;
        pos.z = _cameraZ;
        self.camera.position = pos;
    }
    
    if( (TGGetLogLevel() & LLMeshImporter) != 0 )
        [self dumpMetrics];
    
    _scene = nil; // no need to hang on
    
    return self;
}

-(void)buildNodePainters
{
    static MeshNodePainter * (^createNodePainter)(MeshSceneMeshNode *, Node3d *) = nil;
    
    createNodePainter = ^MeshNodePainter *(MeshSceneMeshNode *node, Node3d *parent)
    {
        MeshNodePainter * painterObj = [[MeshNodePainter alloc] initWithNode:node];
        [parent appendChild:painterObj];
        if( node->_children )
            [node->_children each:^(id key, MeshSceneMeshNode *child) {
                createNodePainter(child,painterObj);
            }];
        return painterObj;
    };
    
    NSMutableArray * painterObjects = [NSMutableArray new];
    
    for( MeshSceneMeshNode *node in  _scene->_meshes )
    {
        MeshNodePainter * painterObj = createNodePainter(node,self);
        [painterObjects addObject:painterObj];
    }
    
    createNodePainter = nil;
    
    _nodePainters = [NSArray arrayWithArray:painterObjects];
}

-(void)setColladaFile:(NSString *)colladaFile
{
    _colladaFile = colladaFile;
}

-(MeshSceneArmatureNode *)findJointWithName:(NSString *)name
{
    for( MeshNodePainter * nodePainter in _nodePainters )
    {
        for( Joints * joints in nodePainter->_jointFeatures )
        {
            MeshSceneArmatureNode * joint = [joints jointWithName:name];
            if( joint )
                return joint;
        }
    }
    
    return nil;
}

-(void)update:(NSTimeInterval)dt
{
    [super update:dt];
    [_animations update:dt];
}

-(void)makeLights
{
    Light * light = [Light new];
    Lights * lights = [Lights new];
    [lights addLight:light];
    self.lights = lights;
}

@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


@implementation MeshImportPainter (Dump)
-(void)dumpMetrics
{
    float minX = 0, maxX = 0, minY = 0, maxY = 0, minZ = 0, maxZ = 0;
    for( MeshSceneMeshNode * meshNode in _scene->_meshes )
    {
        for( MeshGeometry * geomoetry in meshNode->_geometries )
        {
            float * p = geomoetry->_buffer;
            unsigned int stride = 0;
            for( int s = 0; s < geomoetry->_numStrides; s++ )
            {
                stride += geomoetry->_strides[s].numbersPerElement;
            }
            for( int i = 0; i < geomoetry->_numVertices; i++ )
            {
                GLKVector3 * verts = (GLKVector3 *)p;
                if( verts->x < minX ) minX = verts->x;
                if( verts->x > maxX ) maxX = verts->x;
                if( verts->y < minY ) minY = verts->y;
                if( verts->y > maxY ) maxY = verts->y;
                if( verts->z < minZ ) minZ = verts->z;
                if( verts->z > maxZ ) maxZ = verts->z;
                p += stride;
            }
        }
    }
    
    float centerX = (maxX + minX) / 2.0;
    float centerY = (maxY + minY) / 2.0;
    float centerZ = (maxZ + minZ) / 2.0;
    
    TGLogp(LLMeshImporter, @"Scene dim: {%G,%G,%G} - {%G,%G,%G} ceneter: {%G,%G,%G}",
           minX, minY, minZ,
           maxX, maxY, maxZ,
           centerX, centerY, centerZ);
    
    Lights * lights = self.lights;
    if( lights )
        [lights dump:LLMeshImporter];
    GLKVector3 cpos = self.camera.position;
    TGLogp(LLMeshImporter, @"Camera: (%G, %G, %G}", cpos.x, cpos.y, cpos.z );
}
@end

