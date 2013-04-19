//
//  Light.m
//  TimbreGroove
//
//  Created by victor on 1/21/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Light.h"
#import "GenericShader.h"
#import "Generic.h"

@implementation DirectionalLight

-(id)init
{
    if( (self = [super init]) )
    {
        _direction = (GLKVector3){0, 0.5, 0};
        _position  = (GLKVector3){0, 0,   -1};
    }
    
    return self;
}

-(void)getShaderFeatureNames:(NSMutableArray *)putHere
{
    [putHere addObject:kShaderFeatureNormal];
}

-(void)bind:(Shader *)shader object:(Generic *)object
{
    GLKMatrix4 pvm = [object calcPVM];
    GLKMatrix3 normalMat = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(pvm), NULL);
    [shader writeToLocation:gv_normalMat type:TG_MATRIX3 data:normalMat.m];
    
    [shader writeToLocation:gv_lightDir type:TG_VECTOR3 data:_direction.v];
    [shader writeToLocation:gv_lightPosition type:TG_VECTOR3 data:_position.v];
}
-(void)unbind:(Shader *)shader {}
-(void)setShader:(Shader *)shader{}

@end
