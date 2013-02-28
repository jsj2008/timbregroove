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
#import "GraphView+Touches.h"

@interface TG3dObject () {
    PointPlayer * _ptPlayer;
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
        _autoRenderChildren = true;
        _parameters = [NSMutableArray new];
    }
    return self;
}

-(id)wireUp
{
    self.settingsAreDirty = false;
    [self installParameters];
    return self;
}

-(id)wireUpWithViewSize:(CGSize)viewSize
{
    return [self wireUp];
}

-(void)installParameters
{
    
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

#pragma mark record stuff

-(void)didAttachToView:(GraphView *)view
{
    [view.tapRecordGesture addReceiver:self];
}

-(void)didDetachFromView:(GraphView *)view
{
    [view.tapRecordGesture removeReceiver:self];
}

-(void)TapRecordGesture:(TapRecordGesture*)rg recordingWillBegin:(PointRecorder *)recorder
{
    _ptPlayer = nil;
}

-(void)TapRecordGesture:(TapRecordGesture*)rg recordingBegan:(PointRecorder *)recorder
{
    _ptPlayer = nil;
}

-(void)TapRecordGesture:(TapRecordGesture*)rg recordedPt:(GLKVector3)pt
{
//    [self playNoteAtPt:pt];
}

-(void)TapRecordGesture:(TapRecordGesture*)rg recordingDone:(PointRecorder *)recorder
{
    _ptPlayer = [recorder makePlayer];
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
    GLboolean prevDT;
    if( !_fbo.allowDepthCheck )
    {
        prevDT = glIsEnabled(GL_DEPTH_TEST);
        glDisable(GL_DEPTH_TEST);
    }
    glClearColor(_fbo.clearColor.r,_fbo.clearColor.g,_fbo.clearColor.b,_fbo.clearColor.a);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    [self render:_fbo.width h:_fbo.height];
    if( !_fbo.allowDepthCheck  && prevDT == GL_TRUE )
        glEnable(GL_DEPTH_TEST);
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
        NSLog(@"Missing shader (did you call wireUp?)");
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
        NSLog(@"Missing camera  (did you call wireUp?)");
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
        NSLog(@"Missing graph view member  (did you call wireUp?)");
        exit(1);
    }
#endif
    return e ? e->_view : nil;
}

#pragma mark Options settings

-(NSArray *)getSettings
{
    return nil;
}

-(NSDictionary *)getParameters
{
    Shader * shader = self.shader;
    NSMutableDictionary * dict = [NSMutableDictionary new];
    for( ShaderParameter * param in _parameters )
    {
        param.shader = shader;
        dict[param.parameterName] = param.myParamBlock;
    }
    return dict;
}
@end
