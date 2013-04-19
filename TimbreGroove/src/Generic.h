//
//  TGGenericElement.h
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TG3dObject.h"
#import "GenericShader.h"

#ifndef SKIP_GENERIC_DECLS
extern NSString const * kShaderFeatureColor;
extern NSString const * kShaderFeatureNormal;
extern NSString const * kShaderFeatureTexture;
extern NSString const * kShaderFeatureUColor;
extern NSString const * kShaderFeatureTime;
extern NSString const * kShaderFeatureDistortTexture;
extern NSString const * kShaderFeaturePsychedelic;
extern NSString const * kShaderFeatureSpotFilter;
extern NSString const * kShaderFeatureBones;
extern NSString const * kShaderFeatureAmbientLighting;
extern NSString const * kShaderFeaturePhongLighting;
#endif

@class MeshBuffer;
@class Texture;
@class Shader;
@class Generic;

@protocol ShaderFeature <NSObject>
-(void)getShaderFeatureNames:(NSMutableArray *)putHere;
-(void)setShader:(Shader *)shader;
-(void)bind:(Shader *)shader object:(Generic*)object;
-(void)unbind:(Shader *)shader;
@end

@interface Generic : TG3dObject
// derivations write these
-(void)createBuffer;
-(void)createShader; // add shader features (materials, lights, etc.) then call base class

// default behavoirs of these should be fine:
-(void)addBuffer:(MeshBuffer *)buffer;
-(void)addShaderFeature:(id<ShaderFeature>)feature;
-(void)addIndexShape:(MeshBuffer *)indexBuffer
            features:(NSArray *)shaderFeatures;

-(void)getShaderFeatureNames:(NSMutableArray *)putHere;

-(void)removeShaderFeature:(id<ShaderFeature>)feature;

@end

