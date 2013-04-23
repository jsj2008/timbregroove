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

/*

 Shader variables have 3 representations:
    (a) 'name'          the text name as they appear in the shader (e.g. u_someVarName)
    (b) 'indexIntoName' the index into array that will represent both during runtime
    (c) 'location'      the location handle assigned to it by openGL (e.g. via glGetUniformLocation)
 
 Init a shader with an array of names and from then on refer ONLY to a variable
 in terms of an index into that array. The name array must have the attributes bunched up at the
 beginning of the array, followed the uniforms.
 
 For special cases, you can retieve the coresponding name or location
 -(GLint)location:(int)indexIntoNames;
 -(const char *)nameForIndex:(int)indexIntoNames;

 
*/
@class Node3d;

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
    GLint *       _locations;
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

- (void) writeToLocation:(int)indexIntoNames type:(TGUniformType)type data:(void*)data;
- (void) writeToLocation:(int)indexIntoNames type:(TGUniformType)type data:(void*)data count:(unsigned int)count;
- (void) writeToLocationTranspose:(int)indexIntoNames type:(TGUniformType)type data:(void*)data count:(unsigned int)count;

- (void) prepareRender:(Node3d *)object;

// Get the gl location for a variable (uniform or attribute) if you want to call
// glUniform* yourself:
-(GLint) location:(int)indexIntoNames;
-(const char *)nameForIndex:(int)indexIntoNames;

// Without target objects...
// ----------------------------
-(Parameter *)floatParameter:(NSMutableDictionary *)putHere
              indexIntoNames:(int)idx
                       value:(float)value
                  neg11range:(FloatRange)range;
-(Parameter *)floatParameter:(NSMutableDictionary *)putHere indexIntoNames:(int)idx value:(float)value range:(FloatRange)range;
-(Parameter *)floatParameter:(NSMutableDictionary *)putHere indexIntoNames:(int)idx;
-(Parameter *)pointParameter:(NSMutableDictionary *)putHere indexIntoNames:(int)idx;
-(Parameter *)vec3Parameter :(NSMutableDictionary *)putHere indexIntoNames:(int)idx;


// With target objects...
// ----------------------------
-(Parameter *)floatParameter:(NSMutableDictionary *)putHere
              indexIntoNames:(int)idx
                       value:(float)value
                  neg11range:(FloatRange)range
                   forObject:(Node3d *)target;
-(Parameter *)floatParameter:(NSMutableDictionary *)putHere indexIntoNames:(int)idx value:(float)value range:(FloatRange)range forObject:(Node3d *)obj;
-(Parameter *)floatParameter:(NSMutableDictionary *)putHere indexIntoNames:(int)idx forObject:(Node3d *)obj;
-(Parameter *)pointParameter:(NSMutableDictionary *)putHere indexIntoNames:(int)idx forObject:(Node3d *)obj;
-(Parameter *)vec3Parameter :(NSMutableDictionary *)putHere indexIntoNames:(int)idx forObject:(Node3d *)obj;


@property (nonatomic) bool acceptMissingVars;

@end
