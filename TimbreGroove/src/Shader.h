//
//  TGShader.h
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"
#import "Parameter.h"

@class TG3dObject;

@interface ShaderWrapper : NSObject {
@protected
    GLuint _program;
}

- (void) use;

- (BOOL) loadAndCompile:(const char*)vert andFragment:(const char*)frag andHeaders:(NSString *)headers;

@property (nonatomic) GLuint program;

@end

@interface Shader : ShaderWrapper {
@protected
    GLint *       _vars;
}

+(id)shaderFromPoolWithVertex:(const char *)vert
                  andFragment:(const char *)frag
                  andVarNames:(const char **)names
                  andNumNames:(int)numNames
                  andLastAttr:(int)lastAttr
                   andHeaders:(NSString *)headers;

+(id)shaderWithVertex:(const char *)vert
          andFragment:(const char *)frag
          andVarNames:(const char **)names
          andNumNames:(int)numNames
          andLastAttr:(int)lastAttr
           andHeaders:(NSString *)headers;


-(id)initWithVertex:(const char *)vert
        andFragment:(const char *)frag
        andVarNames:(const char **)names
        andNumNames:(int)numNames
        andLastAttr:(int)lastAttr
         andHeaders:(NSString *)headers;

- (void)  writeToLocation:(int)indexIntoNames type:(TGUniformType)type data:(void*)data;

- (void) prepareRender:(TG3dObject *)object;

// Get the gl location for a variable (uniform or attribute) if you want to call
// glUniform* yourself:
- (GLint) location:(int)indexIntoNames;
-(const char *)nameForIndex:(int)index;


@property (nonatomic) bool acceptMissingVars;

@end

typedef struct ShaderParameterDefinition {
    ParameterDefintion  pd;
    int indexIntoNames;
} ShaderParameterDefinition;

@interface ShaderParameter : Parameter

@property (nonatomic,strong) ParamBlock paramBlock;
-(id)initWithShaderDef:(ShaderParameterDefinition *)sdef;

@property (nonatomic,weak) Shader *shader;
@end
