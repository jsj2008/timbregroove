//
//  CustomPlane.m
//  TimbreGroove
//
//  Created by victor on 12/21/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "CustomPlane.h"
#import "Shader.h"

/*
  Example of a 3d element that uses doesn't use a lot of the
 framework to alloc and draw, mainly raw openGL-es calls
*/
@interface CustomPlane() {
    GLuint _vbuffer;
    GLint _posAttrLoc;
    float _rot;
}
@end
@implementation CustomPlane

-(id)init
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
    
    if( (self = [super init]) )
    {
        glGenBuffers(1, &_vbuffer);
        glBindBuffer(GL_ARRAY_BUFFER, _vbuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(v), v, GL_STATIC_DRAW);
        self.shader = [ShaderFactory getShader:@"generic" klass:[Shader class] header:nil];
        [self.shader use];
        GLKVector4 c = { 1, 0, 0, 1 };
        [self.shader.locations write:@"u_color" type:TG_VECTOR4 data:c.v];
        _posAttrLoc = glGetAttribLocation(self.shader.program, "a_position");
        
    }
    
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
    [self.shader use];
    glBindBuffer(GL_ARRAY_BUFFER, _vbuffer);
    glEnableVertexAttribArray(_posAttrLoc);
    glVertexAttribPointer(_posAttrLoc, 3, GL_FLOAT, false, 0, 0);
    GLKMatrix4 pvm = [self calcPVM];
    [self.shader.locations write:@"u_pvm" type:TG_MATRIX4 data:pvm.m];
    glDrawArrays(GL_TRIANGLES, 0, 6);
}

@end
