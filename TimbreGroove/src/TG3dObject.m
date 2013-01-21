//
//  TGElement.m
//  TimbreGroove
//
//  Created by victor on 12/13/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TG3dObject.h"
#import "Camera.h"
#import "Shader.h"
#import "MeshBuffer.h"
#import "FBO.h"


@implementation TG3dObject

#pragma mark -
#pragma mark Lifetime

-(id)init
{
    if( (self = [super init]) )
    {
        self.scaleXYZ = 1.0;
    }
    return self;
}

-(id)wireUp
{
    return self;
}


-(void)clean
{
    _shader = nil;
    _fbo = nil;
    // _camera = nil; ???
}

-(id)rewire
{
    self.needsRewire = false;
    [self cleanChildren];
    [self clean];
    return [self wireUp];
}

#pragma mark inialize

- (NSString *)getShaderHeader
{
    // #define for shaders go here (in derivations)
    return @"";
}


#pragma mark update render

-(void)update:(NSTimeInterval)dt
{
    // update model and camera matrix here
    // so children can adjust accordingly
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
}


-(void)renderToFBO
{
    [self renderToFBOWithClear:true andBindFlags:FBOBF_None];
}

-(void)renderToFBOWithClear:(bool)clear
{
    [self renderToFBOWithClear:clear andBindFlags:FBOBF_None];
}

-(void)renderToFBOWithClear:(bool)clear andBindFlags:(FBO_BindFlags)flags;
{
    Camera * saveCamera = _camera;
    _camera = [IdentityCamera new];
    if( (flags & FBOBF_SkipBind) == 0 )
        [_fbo bindToRender];
    glViewport(0, 0, _fbo.width, _fbo.height);
    if( clear )
    {
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    }
    [self render:_fbo.width h:_fbo.height];
    if( (flags & FBOBF_SkipUnbind) == 0 )
        [_fbo unbindFromRender];
    _camera = saveCamera;
}

// capture hack
// TODO: in the future: not so much with the hacking
-(void)renderToCaptureAtBufferLocation:(GLint)location
{
    
}

#pragma mark Perspective

-(void)setScaleXYZ:(float)scaleXYZ
{
    _scale.x = _scale.y = _scale.z = scaleXYZ;
}

-(GLKMatrix4)modelView
{
    GLKMatrix4 mx = GLKMatrix4MakeTranslation( _position.x, _position.y, _position.z );
    
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

#pragma mark Upward traversing accessors

-(Shader *)shader
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

-(Camera *)ownCamera
{
    return _camera;
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

#pragma mark Options settings

-(NSArray *)getSettings
{
    return @[];
}

@end
