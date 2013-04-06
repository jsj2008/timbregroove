//
//  Mesh.m
//  aotkXML
//
//  Created by victor on 3/28/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "MeshScene.h"
#import "Log.h"

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  Mesh  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@implementation MeshScene

-(id)init
{
    self = [super init];
    if( self )
    {
        _animations = [NSMutableArray new];
    }
    return self;
}

-(MeshGeometry *)getGeometry:(NSString *)name
{
    return _mesh->_skin ? _mesh->_skin->_geometry : _mesh->_geometry;
}

-(void)calcAnimationMatricies
{
    if( _animations )
    {
        [_animations each:^(MeshAnimation * animation) {
            [(MeshSceneArmatureNode *)animation->_target matrix];
        }];
    }
}

-(void)calcMatricies
{
    static void (^calcArmatureMarticies)(id,MeshSceneArmatureNode *) = nil;
    
    if( _armatureTree )
    {
        calcArmatureMarticies = ^(id key, MeshSceneArmatureNode * node) {
            if( node->_children )
                [node->_children each:calcArmatureMarticies];
            else
                [node matrix];
        };
        calcArmatureMarticies(nil,_armatureTree);
    }
}

@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  MeshSkinning @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@implementation MeshSkinning

-(id)init
{
    self = [super init];
    if( self )
    {
        _influencingJoints = [NSMutableArray new];
    }
    return self;
}

-(void)dealloc
{
    if( _influencingJointCounts )
        free(_influencingJointCounts);
    if( _packedWeightIndices )
        free(_packedWeightIndices);
    if( _vectorIndex )
        free(_vectorIndex);
}

// yea, yea, this is just the first pass
// most of this should be cache and/or in the
// shader, I get it.
-(void)influence:(MeshGeometryBuffer *)buffer
            dest:(float *)dest
{
    unsigned int   currPos  = 0;
    int            ji       = 0;
    int            wi;
    float          weight;
    GLKVector3     vec3;
    
    unsigned int   numJoints    = [_influencingJoints count];
    GLKMatrix4 *   jointMats    = malloc( sizeof(GLKMatrix4) * numJoints * 2);
    GLKMatrix4 *   jointInvMats = jointMats + numJoints;
    bool      *    doTranslate  = malloc( sizeof(bool) * numJoints );
    
    __block int bji = 0;
    
    [_influencingJoints each:^(MeshSceneArmatureNode * joint) {
        
        GLKMatrix4 m = [joint matrix];
        
        doTranslate[bji] = joint->_translateHack;
        if( doTranslate[bji] )
        {
            m = (GLKMatrix4) {
                1, 0, 0, 0,
                0, 1, 0, 0,
                0, 0, 1, 0,
                m.m03,m.m13,m.m23, 1
            };
        }
        
        jointMats[bji]     = m;
        jointInvMats[bji]  = joint->_invBindMatrix;
        bji++;
    }];
    
    GLKVector3 * vec = (GLKVector3 *)buffer->data;
    GLKVector3 * p   = (GLKVector3 *)dest;
    
    for( int i = 0; i < _numInfluencingJointCounts; i++ )
    {
        int numberOfJointsApplied = _influencingJointCounts[ i ];
        
        GLKVector3 outVec3 = (GLKVector3){0,0,0};
        
        for( unsigned int n = 0; n < numberOfJointsApplied; n++  )
        {
            ji = _packedWeightIndices[ currPos + _jointWOffset ];
            wi = _packedWeightIndices[ currPos + _weightFOffset];
            
            currPos += 2;
            
            weight = _weights[ wi ];
            
            vec3 = GLKMatrix4MultiplyVector3( jointInvMats[ji], vec[i] );
            if( doTranslate[ji] )
                vec3 = GLKMatrix4MultiplyVector3WithTranslation(jointMats[ji], vec3);
            else
                vec3 = GLKMatrix4MultiplyVector3( jointMats[ji],    vec3);
            vec3 = GLKVector3MultiplyScalar ( vec3,             weight);
            outVec3 = GLKVector3Add(outVec3, vec3);
        }

        unsigned int vindex = _vectorIndex ? _vectorIndex[i] : i;
        p[vindex] = outVec3;
    }
    
    free(jointMats);
    free(doTranslate);
}

@end
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@  MeshAnimation  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@implementation MeshAnimation

-(void)dealloc
{
    free(_keyFrames);
    free(_transforms);
}

@end
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  MeshGeometry  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@implementation MeshGeometry

-(void)dealloc
{
    for( int i = 0; i < kNumMeshSemanticKeys; i++ )
    {
        if( _buffers[i].data )
            free(_buffers[i].data);
    }
}

@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  SceneNode(s) @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@implementation MeshSceneNode 

-(void)setTransform:(GLKMatrix4)transform
{
    _transform = transform;
}

-(void)addChild:(MeshSceneNode *)child name:(NSString *)name
{
    if( !_children )
        _children = [NSMutableDictionary new];
    _children[name] = child;
}
@end

@implementation MeshSceneArmatureNode {
    bool _gotInversere;
}


-(GLKMatrix4)matrix
{
    if( _parent )
    {
        GLKMatrix4 parentWorld = [_parent matrix];
        _world = GLKMatrix4Multiply(_transform, parentWorld);
    }
    else
    {
        _world = _transform;
    }
    if( !_gotInversere )
    {
        bool invertable;
        _invBindPoseMatrix = GLKMatrix4Invert(_world,&invertable);
        _gotInversere = true;
    }
    return _world;
}
@end

@implementation MeshSceneMeshNode
@end
