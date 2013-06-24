//
//  Fractal.m
//  TimbreGroove
//
//  Created by victor on 1/3/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Fractal.h"
#import "GenericShader.h"
#import "GridPlane.h"

@interface Fractal() {
    GLKVector2 _complexConstant;
    float      _viewportSize;
    float      _blend;
    GLint      _u_posLocation;
    GLint      _u_complexConstantLocation;
    GLint      _u_viewportSizeLocation;
    GLint      _u_blendLocation;
    GLint      _u_backColorLocation;
    MeshBuffer * _buffer;
    double  _tracker;
    ShaderWrapper * _shader;
}

@end
@implementation Fractal

-(id)wireUp
{
    [self createBuffer];
    [self createShader];
    return self;
}

-(void)createBuffer
{
    GridPlane * gp = [GridPlane gridWithIndicesIntoNames:@[@(gv_pos)]];
    [self addBuffer:gp];
    _buffer = gp;
}

-(void)createShader
{
    _shader = [[ShaderWrapper alloc] init];
    [_shader loadAndCompile:"fractal" andFragment:"fractal" andHeaders:nil];

    GLuint program = _shader.program;
    _u_complexConstantLocation = glGetUniformLocation(program, "u_complexConstant");
    _u_viewportSizeLocation    = glGetUniformLocation(program, "u_viewportSize");
    _u_blendLocation           = glGetUniformLocation(program, "u_blend");
    _u_backColorLocation       = glGetUniformLocation(program, "u_backColor");
    _u_posLocation             = glGetAttribLocation(program,  "a_position");
    
    GLKVector4 bc = { 0.0, 0.0, 0.45, 1 };
    _backColor = bc;
    
    self.shader = (Shader *)_shader; // eek
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
    [_shader use];
    glUniform2fv(_u_complexConstantLocation, 1, _complexConstant.v);
    glUniform1f( _u_blendLocation, _blend);
    glUniform2f(_u_viewportSizeLocation, (GLfloat)w, (GLfloat)h);
    glUniform4fv(_u_backColorLocation, 1, _backColor.v);
    [_buffer bindToTempLocationVBA:_u_posLocation];
    [_buffer draw];
    [_buffer unbind];
}


@end
