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

@interface Texture : NSObject

@property (nonatomic) GLint      uLocation;    // frag. shader sampler uniform location

-(id)initWithFileName:(NSString *)fileName;
-(id)initWithGlTextureId:(GLuint)glTextureId;
-(id)initWithString:(NSString *)text;

-(bool)loadFromFile:(NSString *)fileName;

-(void)bindTarget:(int)i;
-(void)unbind;

// er, instant obsolesence
-(void)bind:(Shader *)shader target:(int)i;

@end
