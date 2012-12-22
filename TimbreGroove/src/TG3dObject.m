//
//  TGElement.m
//  TimbreGroove
//
//  Created by victor on 12/13/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TG3dObject.h"
#import "Camera.h"
#import "__Shader.h"
#import "MeshBuffer.h"



@implementation TG3dObject

-(void)update:(NSTimeInterval)dt
{
    // update model and camera matrix here
    // so children can adjust accordingly
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
}

// capture hack
// TODO: don't hack so much
-(void)drawBufferToShader:(__Shader *)shader atLocation:(GLint)location
{
    
}

- (NSString *)getShaderHeader
{
    return @"";
}

-(void)setScaleXYZ:(float)scaleXYZ
{
    _scale.x = _scale.y = _scale.z = scaleXYZ;
}

-(GLKMatrix4)modelView
{
    GLKMatrix4 mx = GLKMatrix4MakeTranslation( _position.x, _position.y, _position.z );
    
    if( _scale.x || _scale.y || _scale.z )
        mx = GLKMatrix4Scale(mx, _scale.x, _scale.y, _scale.z);
    
    if( _rotation.x )
        mx = GLKMatrix4Rotate(mx, _rotation.x, 1.0f, 0.0f, 0.0f);
    if( _rotation.y )
        mx = GLKMatrix4Rotate(mx, _rotation.y, 0.0f, 1.0f, 0.0f);
    if( _rotation.z )
        mx = GLKMatrix4Rotate(mx, _rotation.z, 0.0f, 0.0f, 1.0f);
    
    return mx;    
}

- (GLKMatrix4)calcPVM
{
    return GLKMatrix4Multiply(self.camera.projectionMatrix, self.modelView);
}

-(__Shader *)shader
{
    TG3dObject * e = self;
    
    while( e && e->_shader == nil )
        e = (TG3dObject *)e.parent;
    
#if DEBUG
    if( !e || !e->_shader )
    {
        NSLog(@"Missing shader");
        exit(1);
    }
#endif
    return e ? e->_shader : nil;
}


-(Camera *)camera
{
    TG3dObject * e = self;
    
    while( e && e->_camera == nil )
        e = (TG3dObject *)e.parent;

#if DEBUG
    if( !e || !e->_camera )
    {
        NSLog(@"Missing camera");
        exit(1);
    }
#endif
    return e ? e->_camera : nil;
}

-(GLKView *)view
{
    TG3dObject * e = self;
    
    while( e && e->_view == nil )
        e = (TG3dObject *)e.parent;
    
#if DEBUG
    if( !e || !e->_view )
    {
        NSLog(@"Missing graph view member");
        exit(1);
    }
#endif
    return e ? e->_view : nil;
}

@end
