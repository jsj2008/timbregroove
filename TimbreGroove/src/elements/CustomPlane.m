//
//  CustomPlane.m
//  TimbreGroove
//
//  Created by victor on 12/21/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "CustomPlane.h"
#import "__GenericShader.h"

@interface CustomPlane() {
    GLuint _vbuffer;
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
        self.shader = [ShaderFactory getShader:@"generic" klass:[__Shader class] header:nil];
        [self.shader use];
        GLint loc = glGetAttribLocation(self.shader.program, "a_position");
        glEnableVertexAttribArray(loc);
        glVertexAttribPointer(loc, 3, GL_FLOAT, false, sizeof(float)*3, 0);
        GLKVector4 c = { 1, 0, 0, 1 };
        [self.shader.locations write:@"u_color" type:TG_VECTOR4 data:c.v];
        
    }
    
    return self;
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    GLKMatrix4 pvm = [self calcPVM];
    [self.shader.locations write:@"u_pvm" type:TG_MATRIX4 data:pvm.m];
    glDrawArrays(GL_TRIANGLES, 0, 6);
}
@end
