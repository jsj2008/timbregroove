//
//  TGMaterial.h
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"
#import "Generic.h"

@interface ColorMaterial : NSObject<ShaderFeature>
@property (nonatomic) GLKVector4 color;
+(id)withColor:(GLKVector4)color;
-(void)getShaderFeatureNames:(NSMutableArray *)putHere;
@end

@interface AmbientLighting : NSObject<ShaderFeature>
@property (nonatomic) GLKVector4 ambientColor;
@property (nonatomic) GLKVector4 dirColor;
-(void)getShaderFeatureNames:(NSMutableArray *)putHere;
@end

@interface PhongLighting : NSObject<ShaderFeature>
-(void)setMaterials:(GLKVector4 *)colors values:(float *)values;
-(void)getMaterials:(GLKVector4 **)colors values:(float **)values;

-(void)getShaderFeatureNames:(NSMutableArray *)putHere;
@end

@interface Texture : NSObject<ShaderFeature>

@property (nonatomic) GLint uLocation;    // frag. shader sampler uniform location
@property (nonatomic) bool repeat;
@property (nonatomic,readonly) CGSize orgSize; // size of original image used

-(id)initWithFileName:(NSString *)fileName;
-(id)initWithGlTextureId:(GLuint)glTextureId;
-(id)initWithString:(NSString *)text;
-(id)initWithImage:(UIImage *)image;

-(bool)loadFromFile:(NSString *)fileName;
-(bool)loadFromImage:(UIImage *)image;

-(void)bind:(int)target;

-(void)getShaderFeatureNames:(NSMutableArray *)putHere;

@end

