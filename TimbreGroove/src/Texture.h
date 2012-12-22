//
//  TGTexture.h
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"

@class __Shader;

@interface Texture : NSObject

@property (nonatomic) GLint uLocation;

-(id)initWithFileName:(NSString *)fileName;
-(id)initWithGlTextureId:(GLuint)glTextureId;
-(id)initWithString:(NSString *)text;

-(bool)loadFromFile:(NSString *)fileName;

-(void)bind:(__Shader *)shader target:(int)i;

@end
