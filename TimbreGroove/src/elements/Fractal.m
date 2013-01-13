//
//  Fractal.m
//  TimbreGroove
//
//  Created by victor on 1/3/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Fractal.h"
#import "GenericShader.h"
#import "MeshBuffer.h"

@interface Fractal() {
    GLKVector2 _complexConstant;
    float      _viewportSize;
    float      _blend;
    GLint      _complexConstantLocation;
    GLint      _viewportSizeLocation;
    GLint      _blendLocation;
    GLint      _backColorLocation;
    double  _tracker;
}

@end
@implementation Fractal

// write your own version of this:
-(void)createBuffer
{
    MeshBuffer * b =
    [self createBufferDataByType:@[@(sv_pos)]
                     numVertices:4
                      numIndices:0];
    b.drawType = GL_TRIANGLE_FAN;
}

-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
{
    static GLfloat vertices[] = {
        -1.0f ,-1.0f, 0,
        1.0f, -1.0f, 0,
        1.0f,  1.0f, 0,
        -1.0f,  1.0f, 0 };
    
    memcpy(vertextData, vertices, sizeof(vertices));
}

-(void)createShader
{
    Shader * shader = [ShaderPool getShader:@"fractal" klass:[GenericShader class] header:nil];
    self.shader = shader;

    GLuint program = shader.program;
    _complexConstantLocation = glGetUniformLocation(program, "u_complexConstant");
    _viewportSizeLocation    = glGetUniformLocation(program, "u_viewportSize");
    _blendLocation           = glGetUniformLocation(program, "u_blend");
    _backColorLocation       = glGetUniformLocation(program, "u_backColor");
    
    GLKVector4 bc = { 0, 0.2, 0.5, 1 };
    _backColor = bc;
}

-(void)update:(NSTimeInterval)dt
{
    _tracker += (dt*3.4);
    double tim = _tracker;
    _complexConstant = GLKVector2Make(sin(tim/4.1f), cos(tim/4.1f));
    _blend = sin(tim/3.1f) * cos(tim/5.2f);
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    Shader * shader = self.shader;
    [shader use];
    glUniform2fv(_complexConstantLocation, 1, _complexConstant.v);
    glUniform1f( _blendLocation, _blend);
    glUniform1f(_viewportSizeLocation, (GLfloat)w);
    glUniform4fv(_backColorLocation, 1, _backColor.v);
    MeshBuffer * b = _buffers[0];
    [b bind:shader];
    [b draw];
    
}


@end
