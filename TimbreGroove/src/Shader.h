//
//  TGShader.h
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"

#import "ShaderLocations.h"

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

@protocol ShaderInit <NSObject>
-(id)initWithName:(NSString *)name andHeader:(NSString *)header;
@end

@interface ShaderPool : NSObject
+(id)getShader:(NSString *)name klass:(Class)klass header:(NSString *)header;
@end


@interface Shader : NSObject <ShaderInit> {
@protected
    GLuint _program;
}

@property (nonatomic, strong, getter = getLocations) ShaderLocations * locations;
@property (nonatomic) GLuint program;

- (void)use;

// for derived classes (delegate?)
- (GLint)location:(SVariables)type;

- (BOOL)load:(NSString *)vname withFragment:(NSString *)fname;

@end
