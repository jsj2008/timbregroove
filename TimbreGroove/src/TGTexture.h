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

@interface TGTexture : NSObject

@property (nonatomic) GLuint               aLocation;
@property (nonatomic) GLenum               target;
@property (nonatomic) GLKTextureInfoOrigin origin;
@property (nonatomic) GLint                uLocation;

-(TGTexture *)initWithFileName:(NSString *)fileName;
-(bool)loadFromFile:(NSString *)fileName;

-(void)bind:(Shader *)shader target:(int)i;

@end
