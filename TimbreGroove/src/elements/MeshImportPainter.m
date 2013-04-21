//
//  GenericImport.m
//  TimbreGroove
//
//  Created by victor on 3/29/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "MeshImportPainter.h"
#import "PainterCamera.h"
#import "MeshSceneBuffer.h"
#import "ColladaParser.h"
#import "Material.h"
#import "Light.h"
#import "State.h"
#import "Parameter.h"
#import "Names.h"

#import "Cube.h"

@interface JointPainter : Painter {
@public
    MeshSceneArmatureNode * _node;
}
@property (nonatomic) GLKVector4 color;
-(void)updateTransformFromPos;
@end

@interface MeshPainter : Painter
@end

@implementation MeshPainter {
    MeshSceneMeshNode * _node;
    MeshBuffer * _drawingBuffer;
    GLint _bufferDrawType;
    bool _doWireframe;
    id<ShaderFeature>  _material;
}

-(id)init
{
    TGLog(LLShitsOnFire, @"no init without node please. thank you");
    exit(-1);
}

-(id)initWithNode:(MeshSceneMeshNode *)node drawType:(GLint)bufferDrawType wireframe:(bool)doWireFrame
{
    self = [super init];
    if( self )
    {
        _node = node;
        _bufferDrawType = bufferDrawType;
        _doWireframe = doWireFrame;
    }
    return self;
}

-(id)wireUp
{
    Light * light = [Light new];
    light.position = (GLKVector3){ 0, 3, 0 };
    light.attenuation = (GLKVector3){ 0.5, 0.2, 0};
    light.directional = true;
    
    [self.lights addLight:light];
    
    [super wireUp];
//    self.disableStandardParameters = true;
    return self;
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
    MeshGeometry * geometry = _node->_geometry;
    
    for( MeshSemanticKey key = MSKPosition; key < kNumMeshSemanticKeys; key++ )
    {
        MeshGeometryBuffer * mgb = geometry->_buffers + key;
        if( mgb->data )
        {
            MeshBuffer *              msb = nil;
            MeshGeometryIndexBuffer * mgib = nil;
            
            if( key == MSKPosition )
            {
                if( geometry->_numIndexBuffers > 1 )
                {
                    msb = [[MeshSceneBuffer alloc] initWithGeometryBuffer:mgb
                                                             andIndexData:mgib
                                                   andIndexIntoShaderName:indexIntoNamesMap[key]];
                    
                    for( int i = 0; i < geometry->_numIndexBuffers; i++ )
                    {
                        MeshGeometryIndexBuffer * mgib = geometry->_indexBuffers + i;
                        MeshBuffer * ibuffer = [[MeshBuffer alloc] init];
                        [ibuffer setIndexData:mgib->indexData numIndices:mgib->numIndices];
                        NSArray * materials = nil;
                        if( _node->_materials )
                        {
                            MeshMaterial * mm = _node->_materials[i];
                            id<ShaderFeature> material = [Material withColors:mm->_colors shininess:mm->_shininess doSpecular:mm->_doSpecular];
                            if( mm->_textureFileName )
                                materials = @[ material, [[Texture alloc] initWithFileName:mm->_textureFileName] ];
                            else // should this be an 'AND' instead of an 'else?
                                materials = @[ material ];
                        }
                        else
                        {
                            materials = @[ [Material withColor:(GLKVector4){ 0.7, 0.7, 0.7, 1.0 }] ];
                        }
                        [self addIndexShape:ibuffer features:materials];
                    }
                    
                    [self addBuffer:msb];
                    msb.drawable = false;
                }
                else
                {
                    mgib = geometry->_indexBuffers;
                    msb = [[MeshSceneBuffer alloc] initWithGeometryBuffer:mgb
                                                             andIndexData:mgib
                                                   andIndexIntoShaderName:indexIntoNamesMap[key]];
                    
                    [self addBuffer:msb];
                    
                    if( _node->_materials )
                    {
                        MeshMaterial * mm = _node->_materials[0];
                        id<ShaderFeature> mat = [Material withColors:mm->_colors shininess:mm->_shininess doSpecular:mm->_doSpecular];
                        [self addShaderFeature:mat];
                        if( mm->_textureFileName )
                        {
                            mat = [[Texture alloc] initWithFileName:mm->_textureFileName];
                            [self addShaderFeature:mat];
                        }
                    }
                }

                if( _node->_skin )
                    msb.usage = GL_DYNAMIC_DRAW;
                if( _bufferDrawType )
                    msb.drawType = _bufferDrawType;
                
                if( _doWireframe )
                {
                    /*
                    msb = [[WireFrame alloc] initWithIndexBuffer:mgb->indexData
                                                            data:mgb->data
                                                  geometryBuffer:msb];
                    */
                }
                _drawingBuffer = msb;
            }
            else
            {
                msb = [[MeshSceneBuffer alloc] initWithGeometryBuffer:mgb
                                                         andIndexData:mgib
                                               andIndexIntoShaderName:indexIntoNamesMap[key]];
                msb.drawable = false;
                [self addBuffer:msb];
            }
        }
    }
}

-(void)createShader
{
    if( _material )
        [self addShaderFeature:_material];
    [super createShader];
}

-(void)calculateInfluences
{
    MeshSkinning * skin = _node->_skin;
    
    if( skin )
    {
        MeshGeometry * geometry = _node->_geometry;
        MeshGeometryBuffer * b = geometry->_buffers;
        float * p = malloc( sizeof(float) * b->numFloats );
        [skin influence:b dest:p];
        [_drawingBuffer setData:p];
        free(p);
    }
    
    if( _kids )
       [_kids each:^(MeshPainter *painter) { [painter calculateInfluences]; }];
}

@end
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@implementation MeshImportPainter {
    MeshScene * _scene;
    bool _doWireframe;
    NSArray * _meshPainters;
    NSArray * _jointPainters;
}

- (id)init
{
    self = [super init];
    if (self) {
        _bufferDrawType = GL_TRIANGLES;
        self.disableStandardParameters = true;
    }
    return self;
}


-(id)wireUp
{
    _scene = [ColladaParser parse:_colladaFile];
    [super wireUp];
 //   [self buildJointPainters];
    [self buildMeshPainters];
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
    
    return self;
}

-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];
    
    putHere[kParamSceneAnimation] = [Parameter withBlock:^(int play) {
        _runAnimations = play;
    }];
}

-(void)buildJointPainters
{
    if( !_scene->_joints )
        return;
        
    static GLKVector4 colors[] = {
        { 1, 0,   0, 0.5 },
        { 0, 1,   0, 0.5 },
        { 0, 0.5, 1, 0.5 },
        { 1, 0,   1, 0.5 }
    };
    
    __block int nextColor = 0;
    
    static void (^createJointPainter)(MeshSceneArmatureNode *) = nil;
    
    NSMutableArray * painterObjects = [NSMutableArray new];
    
    createJointPainter = ^(MeshSceneArmatureNode * node) {
        JointPainter * vb = [[JointPainter alloc] init];
        vb->_node = node;
        GLKVector3 vec3 = POSITION_FROM_MAT(node->_world);
        vb.position = vec3;
        [vb updateTransformFromPos];
        vb.color = colors[nextColor];
        nextColor = ++nextColor % (sizeof(colors)/sizeof(colors[0]));
        [self appendChild:[vb wireUp]];
        [painterObjects addObject:vb];
    };
    
    if( _scene->_animations )
    {
        [_scene->_animations each:^(MeshAnimation * animation) {
            createJointPainter((MeshSceneArmatureNode *)animation->_target);
        }];
    }
    else
    {
        [_scene->_meshes each:^(MeshSceneMeshNode * node) {
            if( node->_skin )
                [node->_skin->_influencingJoints each:createJointPainter];
        }];
    }
    
    _jointPainters = [NSArray arrayWithArray:painterObjects];
}

-(void)buildMeshPainters
{
    static MeshPainter * (^createMeshPainter)(MeshSceneMeshNode *, TG3dObject *) = nil;
    
    createMeshPainter = ^MeshPainter *(MeshSceneMeshNode *node, TG3dObject *parent)
    {
        MeshPainter * painterObj = [[MeshPainter alloc] initWithNode:node drawType:_bufferDrawType wireframe:_doWireframe];
        [parent appendChild:[painterObj wireUp]];
        if( node->_children )
            [node->_children each:^(id key, MeshSceneMeshNode *child) {
                createMeshPainter(child,painterObj);
            }];
        return painterObj;
    };
    
    NSMutableArray * painterObjects = [NSMutableArray new];
    
    [_scene->_meshes each:^(MeshSceneMeshNode *node) {
        MeshPainter * painterObj = createMeshPainter(node,self);
        [painterObjects addObject:painterObj];
    }];
    
    _meshPainters = [NSArray arrayWithArray:painterObjects];
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
    else if([drawType caseInsensitiveCompare:@"wireframe"] == NSOrderedSame)
    {
        _bufferDrawType = GL_TRIANGLES;
        _doWireframe = true;
    }
    
}

-(void)releaseScene
{
    _scene = nil;
}

-(void)updatePainters
{
    [_jointPainters each:^(JointPainter *vb) {
        MeshSceneArmatureNode * node = vb->_node;
        GLKVector3 vec3 = POSITION_FROM_MAT( node->_world );
        vb.position = vec3;
    }];
 
    [self calculateInfluences];
}
    
-(void)calculateInfluences
{
    [_meshPainters each:^(MeshPainter *meshPainter) { [meshPainter calculateInfluences]; }];
}

-(void)update:(NSTimeInterval)dt
{
    [super update:dt];
    
    if ( _runAnimations && _scene->_animations )
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
            [self updatePainters];
    }
}

@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


@implementation JointPainter

-(id)wireUp
{
    [super wireUp];
    self.disableStandardParameters = true;
    return self;
}

-(void)createBuffer
{
    MeshBuffer * mb = [Cube cubeWithWidth:0.25
                      andIndicesIntoNames:@[@(gv_pos)]
                                 andDoUVs:false
                             andDoNormals:false];
    
    [self addBuffer:mb];
}

-(void)createShader
{
    [self addShaderFeature:[Material withColor:_color]];
    [super createShader];
}

-(void)updateTransformFromPos
{
    GLKVector3 vec3 = self.position;
    _node->_transform = GLKMatrix4Translate(_node->_invBindMatrix, vec3.x, vec3.y, vec3.z );
}

-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];
    
    Parameter * parameter = [Parameter withBlock:^(TGVector3 vec3) {
        self.position = TG3(vec3);
        [self updateTransformFromPos];
        [(MeshImportPainter *)_parent calculateInfluences];
    }];
    parameter.targetObject = self;
    NSString * paramName = [NSString stringWithFormat:@"controllerPos#%@",_node->_name];
    putHere[paramName] = parameter;
}

@end
