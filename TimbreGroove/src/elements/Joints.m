//
//  Bones.m
//  TimbreGroove
//
//  Created by victor on 4/22/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Joints.h"
#import "MeshScene.h"
#import "Painter.h"

@implementation Joints {
    NSArray *    _nodes;
    unsigned int _numNodes;
    GLKMatrix4 * _matrices;
    GLKMatrix4 * _invBindMats;
}

+(id)withArmatureNodes:(id)nodes
{
    return [[Joints alloc] initWithNodes:nodes];
}

-(id)initWithNodes:(NSArray *)nodes
{
    self = [super init];
    if( self )
    {
        _nodes = nodes;
        _numNodes = [nodes count];
        _matrices    = malloc( sizeof(GLKMatrix4) * _numNodes);
        _invBindMats = malloc( sizeof(GLKMatrix4) * _numNodes);
        unsigned bji = 0;
        for( MeshSceneArmatureNode * joint in _nodes ) {
            _invBindMats[bji++] = joint->_invBindMatrix;
        };        
    }
    return self;
}

-(void)dealloc
{
    free(_matrices);
    free(_invBindMats);
}

-(void)getShaderFeatureNames:(NSMutableArray *)putHere
{
    [putHere addObject:kShaderFeatureBones];
}

-(void)unbind:(Shader *)shader
{
    int clear = 0;
    [shader writeToLocation:gv_numJoints type:TG_INT data:&clear];
}

-(void)bind:(Shader *)shader object:(Painter *)object
{
    if( _disabled )
    {
        int zero = 0;
        [shader writeToLocation:gv_numJoints type:TG_INT data:&zero];
        return;
    }
    
    unsigned bji = 0;
    for( MeshSceneArmatureNode * joint in _nodes ) {
        _matrices[bji++] = [joint matrix];
    };
    
    [shader writeToLocation:gv_numJoints    type:TG_INT data:&_numNodes];
    [shader writeToLocation:gv_jointMats    type:TG_MATRIX4 data:_matrices    count:_numNodes];
    [shader writeToLocation:gv_jointInvMats type:TG_MATRIX4 data:_invBindMats count:_numNodes];
}
@end
