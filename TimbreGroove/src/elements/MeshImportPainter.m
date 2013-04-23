//
//  GenericImport.m
//  TimbreGroove
//
//  Created by victor on 3/29/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

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

@interface JointPainter : Painter {
@public
    MeshSceneArmatureNode * _node;
}
@property (nonatomic) GLKVector4 color;
-(void)updateTransformFromPos;
@end

@interface MeshNodePainter : Painter
@end

@implementation MeshNodePainter {
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

-(id)initWithNode:(MeshSceneMeshNode *)node
         drawType:(GLint)bufferDrawType
        wireframe:(bool)doWireFrame
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
    light.ambient = (GLKVector4){ 1, 1, 1, 1 };
    light.diffuse = (GLKVector4){ 1, 1, 1, 1 };
    GLKVector3 lightPos = (GLKVector3){ -4, 0, 14};
    light.position = lightPos;
    light.attenuation = (GLKVector3){ 0, 0.2, 0 };
    light.point = true;
    
    [self.lights addLight:light];
    
    [super wireUp];
//    self.disableStandardParameters = true;
    
    self.rotation = (GLKVector3){ GLKMathDegreesToRadians(20), GLKMathDegreesToRadians(20), 0 };
    _node = nil; 
    return self;
}

-(void)createBuffer
{
    [_node->_geometries each:^(MeshGeometry * geometry) {
        NSArray * mats = nil;
        if( geometry->_materialName )
        {
            MeshMaterial * mm = _node->_materials[ geometry->_materialName ];
            Material * m = [Material withColors:mm->_colors shininess:mm->_shininess doSpecular:mm->_doSpecular];
            if( mm->_textureFileName )
            {
                Texture * t = [[Texture alloc] initWithFileName:mm->_textureFileName];
                mats = @[ t, m ];
            }
            else
            {
                mats = @[ m ];
            }
        }
        
        MeshBuffer * mb = [[MeshBuffer alloc] init];
        [mb setData:geometry->_buffer
            strides:&geometry->_strides[0]
       countStrides:geometry->_numStrides
        numVertices:geometry->_numVertices
          indexData:NULL
         numIndices:0];
        
        [self addShape:mb features:mats];
    }];
    
    if( _node->_skin )
    {
        [self addShaderFeature:[Joints withArmatureNodes:_node->_skin->_influencingJoints]];
    }
}


@end
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@implementation MeshImportPainter {
    MeshScene * _scene;
    bool _doWireframe;
    NSArray * _nodePainters;
    NSArray * _jointPainters;
    NSArray * _animations;
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

    _animations = _scene->_animations;
    
    [super wireUp];
 //   [self buildJointPainters];
    [self buildNodePainters];
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
    
    _scene = nil; // no need to hang on
    
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
    
    if( _animations )
    {
        [_animations each:^(MeshAnimation * animation) {
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

-(void)buildNodePainters
{
    static MeshNodePainter * (^createNodePainter)(MeshSceneMeshNode *, Node3d *) = nil;
    
    createNodePainter = ^MeshNodePainter *(MeshSceneMeshNode *node, Node3d *parent)
    {
        MeshNodePainter * painterObj = [[MeshNodePainter alloc] initWithNode:node drawType:_bufferDrawType wireframe:_doWireframe];
        [parent appendChild:[painterObj wireUp]];
        if( node->_children )
            [node->_children each:^(id key, MeshSceneMeshNode *child) {
                createNodePainter(child,painterObj);
            }];
        return painterObj;
    };
    
    NSMutableArray * painterObjects = [NSMutableArray new];
    
    [_scene->_meshes each:^(MeshSceneMeshNode *node) {
        MeshNodePainter * painterObj = createNodePainter(node,self);
        [painterObjects addObject:painterObj];
    }];
    
    _nodePainters = [NSArray arrayWithArray:painterObjects];
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
 //   [_nodePainters each:^(MeshNodePainter *meshPainter) { [meshPainter calculateInfluences]; }];
}

-(void)update:(NSTimeInterval)dt
{
    [super update:dt];
    
    if ( _runAnimations && _animations )
    {
        __block bool dirty = false;
        
        [_animations each:^(MeshAnimation * animation) {
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
