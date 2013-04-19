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
#import "SettingsVC.h"
#import "Scene.h"
#import "ConfigNames.h"
#import "State.h"
#import "Names.h"

@interface TG3dObject () {
}
@end

@implementation TG3dObject

#pragma mark -
#pragma mark Lifetime

-(id)init
{
    if( (self = [super init]) )
    {
        self.scaleXYZ = 1.0;
        _parameters = [NSMutableArray new];
    }
    return self;
}

-(id)wireUp
{
    self.settingsAreDirty = false;
    return self;
}

-(id)wireUpWithViewSize:(CGSize)viewSize
{
    return [self wireUp];
}

-(void)clean
{
    _shader = nil;
    _fbo = nil;
}

-(id)settingsChanged
{
    if( self.settingsAreDirty )
    {
        [self cleanChildren];
        [self clean];
        [self wireUp];
    }
    
    return self;
}

#pragma mark update render

-(void)update:(NSTimeInterval)dt
{
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
}


-(void)renderToFBO
{
    Camera * saveCamera = _camera;
    _camera = [IdentityCamera new];
    [_fbo bindToRender];
    glViewport(0, 0, _fbo.width, _fbo.height);
    DepthTestState *dts = [DepthTestState enable:_fbo.allowDepthCheck];
    glClearColor(_fbo.clearColor.r,_fbo.clearColor.g,_fbo.clearColor.b,_fbo.clearColor.a);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    [self render:_fbo.width h:_fbo.height];
    [dts restore];
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
    
#if DEBUGX
    if( !e || !e->_shader )
    {
        TGLog(LLShitsOnFire, @"Missing shader (did you call wireUp?)");
        exit(-1);
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
        TGLog(LLShitsOnFire, @"Missing camera  (did you call wireUp?)");
        exit(1);
    }
#endif
    return e ? e->_camera : nil;
}

-(GraphView *)hasView
{
    TG3dObject * e = self;
    
    while( e && e->_view == nil )
        e = (TG3dObject *)e.parent;
    return e ? e->_view : nil;
}

-(GraphView *)view
{
    TG3dObject * e = self;
    
    while( e && e->_view == nil )
        e = (TG3dObject *)e.parent;
    
#if DEBUG
    if( !e || !e->_view )
    {
        TGLog(LLShitsOnFire, @"Missing graph view member  (did you call wireUp?)");
        exit(1);
    }
#endif
    return e ? e->_view : nil;
}

#pragma mark Options settings

- (void)getSettings:(NSMutableArray *)putHere
{
}

#define RAD_TURNS(f) (f * (M_PI / 180))

-(void)getParameters:(NSMutableDictionary *)parameters
{
    if( !_disableStandardParameters )
    {
        parameters[kParamRotationX] = [Parameter withBlock:^(float f) {
            GLKVector3 r = self.rotation;
            r.x += RAD_TURNS(f * 3);
            self.rotation = r;
        }];
        parameters[kParamRotationY] = [Parameter withBlock:^(float f) {
            GLKVector3 r = self.rotation;
            r.y += RAD_TURNS(f * 3);
            self.rotation = r;
        }];
        parameters[kParamRotationZ] = [Parameter withBlock:^(float f) {
            GLKVector3 r = self.rotation;
            r.z += RAD_TURNS(f * 3);
            self.rotation = r;
        }];
        parameters[kParamCameraRotationX] = [Parameter withBlock:^(float f) {
            Camera * camera = self.camera;
            GLKVector3 r = camera.rotation;
            r.x += RAD_TURNS(f * 3);
            camera.rotation = r;
        }];
        parameters[kParamCameraRotationY] = [Parameter withBlock:^(float f) {
            Camera * camera = self.camera;
            GLKVector3 r = camera.rotation;
            r.y += RAD_TURNS(f * 3);
            camera.rotation = r;
        }];
        parameters[kParamCameraRotationZ] = [Parameter withBlock:^(float f) {
            Camera * camera = self.camera;
            GLKVector3 r = camera.rotation;
            r.z += RAD_TURNS(f * 3);
            camera.rotation = r;
        }];
        parameters[kParamCameraZ] = [Parameter withBlock:^(float f) {
            Camera * camera = self.camera;
            GLKVector3 r = camera.position;
            r.z += f * 3.0;
            camera.position = r;
        }];
        
        parameters[kParamCameraReset] = [Parameter withBlock:^(CGPoint pt) {
            Camera * camera = self.camera;
            camera.position = (GLKVector3){ 0, 0, CAMERA_DEFAULT_Z };
            camera.rotation = (GLKVector3){ 0, 0, 0 };
        }];
    }
}

- (void)getTriggerMap:(NSMutableArray *)putHere
{
    NSArray * maps = [self valueForKey:kConfigSceneConnections];
    if( maps && [maps count])
        [putHere addObjectsFromArray:maps];
}

-(void)triggersChanged:(Scene *)scene
{
    
}

@end
