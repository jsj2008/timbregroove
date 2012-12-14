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
#import "TGViewController.h"

@interface TGElement() {
    NSMutableArray * _buffers;
}

@end

@implementation TGElement

-(void)update:(TGViewController *)vc
{
    // update Camera and ModelView (position,rotation) here
    
}

-(void)render:(TGViewController *)vc
{
    TGShader * shader = self.shader;
    TGCamera * camera = self.camera;
    
    GLKMatrix4 projection = camera.projectionMatrix;
    GLKMatrix4 modelView  = self.modelView;

    shader.pvm = GLKMatrix4Multiply(projection, modelView);

    [shader use];
    
    unsigned int numPhases = _phases ? _phases : 1;
    for( int i = 0; i < numPhases; i++ )
    {
        [self writeUniforms:i];
        [shader preRender:i];
        for( TGVertexBuffer * b in _buffers )
            [b draw];
    }
}

-(void)addBuffer:(TGVertexBuffer *)buffer
{
    if( !_buffers )
        _buffers = [NSMutableArray new];
    [_buffers addObject:buffer];
}

-(void)writeUniforms:(unsigned int)phase
{
}

-(GLKMatrix4)modelView
{
    GLKMatrix4 mx = GLKMatrix4MakeTranslation( _position.x, _position.y, _position.z );
    
    mx = GLKMatrix4Rotate(mx, _rotation.x, 1.0f, 0.0f, 0.0f);
    mx = GLKMatrix4Rotate(mx, _rotation.y, 0.0f, 1.0f, 0.0f);
    mx = GLKMatrix4Rotate(mx, _rotation.z, 0.0f, 0.0f, 1.0f);
    
    return mx;    
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

@end
