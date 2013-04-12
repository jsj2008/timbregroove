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
#import "Parameter.h"
#import "Names.h"

#import "Cube.h"
#import "Camera.h"

@interface VisibleBone : Generic {
@public
    MeshSceneArmatureNode * _node;
}
@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@implementation GenericImport {
    MeshScene * _scene;
    MeshBuffer * _drawingBuffer;
    bool _doWireframe;
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
    self.color = (GLKVector4){ 0.4, 1.0, 1.0, 0.7 };
    [super wireUp];
    [self showArmatures];
    if( _runEmitter )
    {
        LogLevel logl = TGGetLogLevel();
        TGSetLogLevel(logl | LLMeshImporter);
        [_scene emit];
        TGSetLogLevel(logl);
    }
 //   [self playFirstFrame];
    return self;
}

-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];
    
    putHere[kParamSceneAnimation] = [Parameter withBlock:^(int play) {
        _runAnimations = play;
    }];
}

-(void)showArmatures
{
    if( _scene->_armatureTree )
    {
        static GLKVector4 colors[] = {
            { 1, 0,   0, 0.5 },
            { 0, 1,   0, 0.5 },
            { 0, 0.5, 1, 0.5 },
            { 1, 0,   1, 0.5 }
            };
        
        __block int nextColor = 0;
        
  //      float posScale = self.scaleXYZ;
        
        static void (^createBones)(MeshSceneArmatureNode *) = nil;
        
        createBones = ^(MeshSceneArmatureNode * node) {
            VisibleBone * vb = [[VisibleBone alloc] init];
            vb->_node = node;
            GLKVector3 vec3 = POSITION_FROM_MAT(node->_world);
            vb.position = vec3;
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

-(void)createTexturexxx
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
            MeshBuffer * msb = [[MeshSceneBuffer alloc] initWithGeometryBuffer:mgb
                                                             andIndexIntoShaderName:indexIntoNamesMap[key]];
            if( key == MSKPosition )
            {
                //if( _scene->_mesh->_skin )
                //    msb.usage = GL_DYNAMIC_DRAW;
                if( _bufferDrawType )
                    msb.drawType = _bufferDrawType;
                
                if( _doWireframe )
                {
                    msb = [[WireFrame alloc] initWithIndexBuffer:mgb->indexData
                                                                       data:mgb->data
                                                             geometryBuffer:msb];
                    
                }
                _drawingBuffer = msb;
            }
            else
            {
                msb.drawable = false;
            }
            
            [self addBuffer:msb];
        }
    }
    
}

-(void)calculateInfluences
{
    MeshSkinning * skin = _scene->_mesh->_skin;
    
    if( skin )
    {
        MeshGeometry * geometry = [_scene getGeometry:nil];
        MeshGeometryBuffer * b = geometry->_buffers;
        float * p = malloc( sizeof(float) * b->numFloats );
        [skin influence:b dest:p];
        [_drawingBuffer setData:p];
        free(p);
    }    
}

-(void)playFirstFrame
{
    if( _scene->_animations )
    {
        [_scene->_animations each:^(MeshAnimation * animation) {
            
            MeshSceneNode * node = animation->_target;
            node->_transform = animation->_transforms[0];
        }];
        [self updateVisibleBones];
    }
}

-(void)updateVisibleBones
{
    [self.children each:^(VisibleBone *vb) {
        MeshSceneArmatureNode * node = vb->_node;
        GLKVector3 vec3 = POSITION_FROM_MAT( node->_world );
        vb.position = vec3;
    }];
    [self calculateInfluences];
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
            [self updateVisibleBones];
    }
}

@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


@implementation VisibleBone

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

-(void)setPosition:(GLKVector3)vec3
{
    [super setPosition:vec3];
    GLKMatrix4 m = _node->_invBindMatrix;
    _node->_transform = GLKMatrix4Multiply(m, GLKMatrix4MakeTranslation( vec3.x, vec3.y, vec3.z ) );
    [(GenericImport *)_parent calculateInfluences];
}

-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];
    
    Parameter * parameter = [Parameter withBlock:^(TGVector3 vec3) {
        self.position = TG3(vec3);
    }];
    parameter.targetObject = self;
    NSString * paramName = [NSString stringWithFormat:@"controllerPos#%@",_node->_name];
    putHere[paramName] = parameter;
}

@end
