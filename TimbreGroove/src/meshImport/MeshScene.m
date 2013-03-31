//
//  Mesh.m
//  aotkXML
//
//  Created by victor on 3/28/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "MeshScene.h"

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
    if( _weightIndices )
        free(_weightIndices);
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

-(void)addChild:(MeshSceneNode *)child name:(NSString *)name
{
    if( !_children )
        _children = [NSMutableDictionary new];
    _children[name] = child;
}
@end

@implementation MeshSceneArmatureNode

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
    bool invertable;
    _invBindPoseMatrix = GLKMatrix4Invert(_world,&invertable);
    return _world;
}
@end

@implementation MeshSceneMeshNode
@end
