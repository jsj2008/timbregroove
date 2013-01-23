//
//  TGTexture.h
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"

@class Shader;

@interface Material : NSObject

@property (nonatomic) GLKVector4 ambientColor;
@property (nonatomic) GLKVector4 diffuseColor;
@property (nonatomic) GLKVector4 specularColor;
@property (nonatomic) float      shininess;
@end

@interface Texture : Material

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
-(void)unbind;

@end

