//
//  TGGenericElement.h
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TG3dObject.h"
#import "GenericShader.h"
#import "ShaderFeature.h"


#ifndef SKIP_GENERIC_DECLS
extern NSString const * kShaderFeatureColor;
extern NSString const * kShaderFeatureNormal;
extern NSString const * kShaderFeatureTexture;
extern NSString const * kShaderFeatureTime;
extern NSString const * kShaderFeatureDistortTexture;
extern NSString const * kShaderFeatureSpotFilter;
extern NSString const * kShaderFeatureBones;
#endif

@class MeshBuffer;
@class Lights;

@interface Painter : TG3dObject

@property (nonatomic,strong) Lights * lights;

// derivations write these
-(void)createBuffer;
-(void)createShader; // add shader features (materials, textures, lights etc.) then call base class

// default behavoirs of these should be fine:
-(void)addBuffer:(MeshBuffer *)buffer;
-(void)addShaderFeature:(id<ShaderFeature>)feature;
-(void)removeShaderFeature:(id<ShaderFeature>)feature;
-(void)getShaderFeatureNames:(NSMutableArray *)putHere;
-(void)addIndexShape:(MeshBuffer *)indexBuffer
            features:(NSArray *)shaderFeatures;
@end

