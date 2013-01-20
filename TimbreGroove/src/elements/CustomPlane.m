//
//  CustomPlane.m
//  TimbreGroove
//
//  Created by victor on 12/21/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "CustomPlane.h"
#import "GenericShader.h"

/*
  Example of a 3d element that uses doesn't use a lot of the
 framework to alloc and draw, mainly raw openGL-es calls
*/
@interface CustomPlane() {
    GLuint _vbuffer;
    GLint _posAttrLoc;
    GLint _matLocation;
    GLint _colorLocation;
    ShaderWrapper *_shader;
    float _rot;
}
@end
@implementation CustomPlane

-(id)wireUp
{
    static float v[6*3] = {
        //   x   y  z
        -1, -1, 0,
        -1,  1, 0,
        1, -1, 0,
        
        -1,  1, 0,
        1,  1, 0,
        1, -1, 0
    };
    
    [super wireUp];
    glGenBuffers(1, &_vbuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vbuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(v), v, GL_STATIC_DRAW);
    ShaderWrapper * shader = [[ShaderWrapper alloc] init];
    [shader loadAndCompile:"generic" andFragment:"generic" andHeaders:nil];
    GLint program = shader.program;
    _posAttrLoc = glGetAttribLocation(program, "a_position");
    _matLocation = glGetUniformLocation(program, "u_pvm");
    _colorLocation = glGetUniformLocation(program, "u_color");
    glUseProgram(program);
    glUniform4f(_colorLocation, 1, 0, 0, 1);
    _shader = shader;
    return self;
}

-(void)update:(NSTimeInterval)dt
{
    _rot += 4;
    GLKVector3 rot = { 0, GLKMathDegreesToRadians(_rot), 0 };
    self.rotation = rot;
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    glUseProgram(_shader.program);
    glBindBuffer(GL_ARRAY_BUFFER, _vbuffer);
    glEnableVertexAttribArray(_posAttrLoc);
    glVertexAttribPointer(_posAttrLoc, 3, GL_FLOAT, false, 0, 0);
    GLKMatrix4 pvm = [self calcPVM];
    glUniformMatrix4fv(_matLocation, 1, 0, pvm.m);
    glDrawArrays(GL_TRIANGLES, 0, 6);
}

-(void)dealloc
{
    glDeleteBuffers(1, &(_vbuffer));
}
@end
