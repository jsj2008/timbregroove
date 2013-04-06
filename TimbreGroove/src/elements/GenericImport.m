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

#import "Cube.h"
#import "Camera.h"

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
    
    bool _runAnimations;
    
    VisibleBone * _controller;
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
//  [_scene emit];
    self.color = (GLKVector4){ 0.4, 1.0, 1.0, 0.7 };
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
        _controller = (VisibleBone *)self.children[0];
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

-(void)getParameters:(NSMutableDictionary *)putHere
{
    if( _controller )
    {
        Parameter * parameter = [Parameter withBlock:^(TGVector3 vec3) {
            _controller.position = *(GLKVector3 *)&vec3;
            _controller->_node->_transform = (GLKMatrix4){
                1, 0, 0, vec3.y,
                0, 1, 0, -vec3.x,
                0, 0, 1, vec3.z,
                0, 0, 1, 0
            };
           // _controller->_node->_translateHack = false;
            [self calculateInfluences];
        }];
//        parameter.targetObject = _controller;
        putHere[@"controllerPos"] = parameter;
    }
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
        [_mb setData:p];
        free(p);
    }    
}

-(void)update:(NSTimeInterval)dt
{
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
        {
       //     [_scene calcAnimationMatricies];

            [self.children each:^(VisibleBone *vb) {
                MeshSceneArmatureNode * node = vb->_node;
                GLKVector4 vec4 = GLKMatrix4GetRow(node->_world, 3);
                vb.position = *(GLKVector3 *)&vec4;
            }];
            [self calculateInfluences];
        }
    }
    else
    {
        
    }
}
-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    [super render:w h:h];

}
@end
