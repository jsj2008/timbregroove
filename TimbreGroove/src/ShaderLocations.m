//
//  TGVariables.m
//  TimbreGroove
//
//  Created by victor on 12/13/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "ShaderLocations.h"
#import "Shader.h"

@interface ShaderLocations() {
    NSMutableDictionary * _d;
}

@end

@implementation ShaderLocations

-(ShaderLocations *)initWithShader:(Shader *)shader
{
    if( (self = [super init]) )
        _shader = shader;
    
    return self;
}

-(void)write:(NSString *)name type:(TGUniformType)type data:(void*)data
{
    GLuint program = self.shader.program;    
    GLint  glname  = [self locationForName:name program:program];
    [self writeToLocation:glname type:type data:data];
}

-(void)writeToLocation:(GLint)location type:(TGUniformType)type data:(void*)data
{
    switch(type)
    {
        case TG_FLOAT:
            glUniform1f(location, *(GLfloat *)data);
            break;
            
        case TG_VECTOR2:
            glUniform2fv(location, 1, data);
            break;
            
        case TG_VECTOR3:
            glUniform3fv(location, 1, data);
            break;
            
        case TG_VECTOR4:
            glUniform4fv(location, 1, data);
            break;
            
        case TG_MATRIX4:
            glUniformMatrix4fv(location, 1, 0, data);
            break;
            
        case TG_BOOL:
            glUniform1i(location, *(GLint *)data);
            break;
            
        case TG_TEXTURE:
            NSLog(@"can't use TG_TEXTURE here");
            exit(1);
    }
}

- (GLint) locationForName:(NSString *)name program:(GLuint)program
{
	NSNumber * index = _d[name];
    GLint location;
	if (index) {
		location = (GLint)[index intValue];
        
	} else {
        location = glGetUniformLocation(program, [name UTF8String]);
        if( !_d )
            _d = [NSMutableDictionary new];
        _d[name] = @(location);
	}
    return location;
}

@end
