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
extern NSString const * kShaderFeatureDistort;
extern NSString const * kShaderFeatureDistortTexture;
extern NSString const * kShaderFeaturePsychedelic;
extern NSString const * kShaderFeatureSpotFilter;
extern NSString const * kShaderFeatureBones;
#endif

@class MeshBuffer;
@class Texture;
@class Shader;
@class Light;

typedef enum ShaderTimeType {
    kSTT_None,
    kSTT_Custom,     // u_time is allocated but you decide how/when to write to it
    kSTT_Timer,      // self.timer is sent every update, you decide when to 0 it out
    kSTT_CountDown,  // self.countDownBase - self.timer as long as result is >= 0
    kSTT_Total       // self.totalTime is sent every update
} ShaderTimeType;

@interface GenericBase : TG3dObject

@property (nonatomic, readonly) bool hasTexture;


@property (nonatomic,strong) Light * light;

@property (nonatomic) GLKVector4 color;
@property (nonatomic) bool       useColor;

@property (nonatomic) NSTimeInterval countDownBase;
@property (nonatomic) ShaderTimeType timerType;

// derivations write these
-(void)createBuffer;
-(void)configureLighting;

// default behavoirs of these should be fine:
-(void)createShader;
-(void)getBufferLocations;
-(void)getTextureLocations;
-(void)addBuffer:(MeshBuffer *)buffer;

-(void)getShaderFeatures:(NSMutableArray *)features;

@end


/*
  Simple single texture shader support
*/
@interface Generic : GenericBase 
// NSString or filename or NSURL to asset-library
@property (nonatomic, strong)   id        textureFileName;
@property (nonatomic, strong)   Texture * texture;
-(void)createTexture;
@end

/*
   Support for multiple textures.
   N.B. Generic shaders do NOT support this
*/
@interface GenericMultiTextures : Generic
-(void)createTextures;
-(void)addTextureObject:(Texture *)texture;
-(void)replaceTextures:(NSArray *)textures;

@end
