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

#import "Scene.h"
#import "TriggerMap.h"

@interface JointPainter : Painter {
@public
    MeshSceneArmatureNode * _node;
}
@property (nonatomic) GLKVector4 color;
-(void)updateTransformFromPos;
@end

@interface MeshNodePainter : Painter
@property (nonatomic) bool disabled;
@end

@implementation MeshNodePainter {
    MeshSceneMeshNode * _node;
    NSMutableArray *    _jointFeatures;
    FloatParamBlock     _myRotation;
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
    }
    return self;
}

-(void)setDisabled:(bool)disabled
{
    [_jointFeatures each:^(Joints * j) { j.disabled = disabled; }];
}

-(id)wireUp
{
    [self setupLights];
    [super wireUp];
    
    _node = nil; 
    return self;
}

-(void)setupLights
{
    ShaderLight desc = { 0 };
    
    desc.colors.ambient  = (GLKVector4){ 1, 1, 1, 1 };
    desc.colors.diffuse  = (GLKVector4){ 1, 1, 1, 1 };
    desc.position        = (GLKVector4){ -2, 2, 2,        1.0 };
    desc.attenuation     = (GLKVector3){ 0, 0.02, 0 };
    
    desc.spotCutoffAngle = 15.468750;
    desc.spotDirection   = (GLKVector3){ 0.5, -0.5, -0.5 };
    desc.spotDirection   =  GLKVector3Normalize( desc.spotDirection );
    desc.spotFalloffExponent = 44.0;
    
    Light * light = [Light new];
    light.desc = desc;
    
    [self.lights addLight:light];
}

-(void)update:(NSTimeInterval)dt
{
    [super update:dt];
    if( _myRotation )
        _myRotation(-0.8);
}

-(void)triggersChanged:(Scene *)scene
{
    if( scene )
    {
        _myRotation = nil; // [scene.triggers getFloatTrigger:kParamRotationY];
    }
    else
    {
        _myRotation = nil;
    }
}

-(void)createBuffer
{
    [_node->_geometries each:^(MeshGeometry * geometry) {
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
            [importedMats each:^(id mat) {
                [shaderFeatures addObject:mat];
            }];
        }
        
        MeshBuffer * mb = [[MeshBuffer alloc] init];
        [mb setData:geometry->_buffer
            strides:&geometry->_strides[0]
       countStrides:geometry->_numStrides
        numVertices:geometry->_numVertices
          indexData:NULL
         numIndices:0];
        
        [self addShape:mb features:shaderFeatures];
    }];
    
}

@end
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@implementation MeshImportPainter {
    MeshScene * _scene;
    NSArray * _nodePainters;
    NSArray * _jointPainters;
    NSArray * _animations;
}

- (id)init
{
    self = [super init];
    if (self) {
       self.disableStandardParameters = true;
    }
    return self;
}


-(id)wireUp
{
    _scene = [ColladaParser parse:_colladaFile];

    _animations = _scene->_animations;
    
    [super wireUp];
//    [self buildJointPainters];
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
        [self disableAnimation:!play];
    }];
}

-(void)buildJointPainters
{
    if( !_scene->_allJoints )
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
            if( node->_influencingJoints )
                [node->_influencingJoints each:createJointPainter];
        }];
    }
    
    _jointPainters = [NSArray arrayWithArray:painterObjects];
}

-(void)buildNodePainters
{
    static MeshNodePainter * (^createNodePainter)(MeshSceneMeshNode *, Node3d *) = nil;
    
    createNodePainter = ^MeshNodePainter *(MeshSceneMeshNode *node, Node3d *parent)
    {
        MeshNodePainter * painterObj = [[MeshNodePainter alloc] initWithNode:node];
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
    
    createNodePainter = nil;
    
    _nodePainters = [NSArray arrayWithArray:painterObjects];
}

-(void)setColladaFile:(NSString *)colladaFile
{
    _colladaFile = colladaFile;
}

-(void)updatePainters
{
    [_jointPainters each:^(JointPainter *vb) {
        MeshSceneArmatureNode * node = vb->_node;
        GLKVector3 vec3 = POSITION_FROM_MAT( node->_world );
        vb.position = vec3;
    }];
}

-(void)disableAnimation:(bool)value
{
    [_nodePainters each:^(MeshNodePainter *mnp) {
        mnp.disabled = value;
    }];
}

-(void)update:(NSTimeInterval)dt
{
    [super update:dt];
    
    if ( _runAnimations && _animations )
    {
        for ( MeshAnimation * animation in _animations )
        {
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
            }
        };
        
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
        [(MeshImportPainter *)_parent updatePainters];
    }];
    parameter.targetObject = self;

    NSString * paramName = [kParamJointPosition stringByAppendingParamTarget:_node->_name];
    putHere[paramName] = parameter;
}

@end
