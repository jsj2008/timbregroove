//
//  Mesh.m
//  aotkXML
//
//  Created by victor on 3/28/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "MeshScene.h"
#import "Log.h"
#import "TGTypes.h"

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

-(void)dealloc
{
    TGLog(LLObjLifetime, @"%@ released", self);
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
    
    if( _allJoints )
    {
        calcArmatureMarticies = ^(id key, MeshSceneArmatureNode * node) {
            if( node->_children )
                [node->_children each:calcArmatureMarticies];
            else
                [node matrix];
        };
        
        [_allJoints each:^(id sender) {
            calcArmatureMarticies(nil,sender);
        }];
        
        calcArmatureMarticies = nil;
    }
}

@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  MeshGeometry  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@implementation MeshGeometry

-(void)dealloc
{
    TGLog(LLObjLifetime, @"%@ released", self);
    free(_buffer);
}

@end

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  SceneNode(s) @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


@implementation MeshSceneNode

- (void)dealloc
{
    TGLog(LLObjLifetime, @"%@ released",self);
}

-(void)setTransform:(GLKMatrix4)transform
{
    _transform = transform;
}

-(void)addChild:(MeshSceneNode *)child name:(NSString *)name
{
    if( !_children )
        _children = [NSMutableDictionary new];
    child->_parent = self;
    _children[name] = child;
}

-(GLKMatrix4)matrix
{
    if( _parent )
    {
        GLKMatrix4 parentWorld = [_parent matrix];
        _world = GLKMatrix4Multiply(parentWorld,_transform);
    }
    else
    {
        _world = _transform;
    }
    return _world;
}

@end

@implementation MeshSceneArmatureNode
@end

@implementation MeshSceneMeshNode
@end


