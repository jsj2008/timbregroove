//
//  TGShader.h
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"

#import "TGVariables.h"

/*
 
 Two conflicting scenarios:
 
 In one case you have a mesh (perhaps animation, textures, etc.) that just needs
 to be ouput with a generic shader. 

 Services needed:
 - buffers*
 - textures*
 - matrix operations*
 - shader generate
 - hide all uniforms, assuming the following
 --- position/mesh
 --- sampler/texture
 --- normals
 --- lighting
 - lighting
 
 In another case you have a very specific special fx shader with very specific
 uniforms and attribute names. 
 
 Services needed:
 - buffers*
 - textures*
 - matrix operations*
 - shader reading/compiling
 - random uniform access

 */
@interface TGShader : NSObject {
@protected
    GLuint _program;
}

+ (TGShader *)shader:(NSString *)name;

- (TGShader *)initWithName:(NSString *)name;

@property (nonatomic, strong) TGVariables * uniforms;
@property (nonatomic)         GLuint        program;

- (void)use;

// for derived classes (delegate?)
- (NSString *)processShaderSrc:(NSString *)src type:(GLenum)type;
- (GLint)location:(SVariables)type;

- (BOOL)load:(NSString *)vname withFragment:(NSString *)fname;

@end
