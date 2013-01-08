//
//  TGVariables.h
//  TimbreGroove
//
//  Created by victor on 12/13/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"


@class Shader;

@interface ShaderLocations : NSObject

@property (nonatomic,weak,readonly) Shader * shader;

-(ShaderLocations *)initWithShader:(Shader *)shader;

-(void)write:(NSString *)name type:(TGUniformType)type data:(void*)data;
-(void)writeToLocation:(GLint)location type:(TGUniformType)type data:(void*)data;

- (GLint) locationForName:(NSString *)name;

@end
