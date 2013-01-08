//
//  TGElement.m
//  TimbreGroove
//
//  Created by victor on 12/13/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGElement.h"
#import "TGCamera.h"
#import "TGShader.h"
#import "TGVertexBuffer.h"



@implementation TGElement

-(void)update:(NSTimeInterval)dt
{
    // update model and camera matrix here
    // so children can adjust accordingly
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
}

-(void)drawBufferToShader:(TGShader *)shader atLocation:(GLint)location
{
    
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

-(TGShader *)shader
{
    TGElement * e = self;
    
    while( e && e->_shader == nil )
        e = (TGElement *)e.parent;
    
    return e ? e->_shader : nil;
}


-(TGCamera *)camera
{
    TGElement * e = self;
    
    while( e && e->_camera == nil )
        e = (TGElement *)e.parent;
    
    return e ? e->_camera : nil;
}

-(GLKView *)view
{
    TGElement * e = self;
    
    while( e && e->_view == nil )
        e = (TGElement *)e.parent;
    
    return e ? e->_view : nil;
}

@end
