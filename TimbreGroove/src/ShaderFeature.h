//
//  ShaderFeature.h
//  TimbreGroove
//
//  Created by victor on 4/19/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

@class Shader;
@class Generic;

@protocol ShaderFeature <NSObject>
-(void)getShaderFeatureNames:(NSMutableArray *)putHere;
-(void)setShader:(Shader *)shader;
-(void)bind:(Shader *)shader object:(Generic*)object;
-(void)unbind:(Shader *)shader;
@end

@interface ShaderBinder : NSObject<ShaderFeature>
@end