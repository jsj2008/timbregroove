//
//  TGMaterial.h
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"
#import "ShaderFeature.h"

@interface Material : NSObject<ShaderFeature>
@property (nonatomic) MaterialColors colors;
@property (nonatomic) float shininess;
@property (nonatomic) bool doSpecular;

@property (nonatomic) GLKVector4 ambient;
@property (nonatomic) GLKVector4 diffuse;
@property (nonatomic) NSString * name;

+(id)withColor:(GLKVector4)color;
+(id)withColors:(MaterialColors)matcolors shininess:(float)shininess doSpecular:(bool)doSpecular;
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

