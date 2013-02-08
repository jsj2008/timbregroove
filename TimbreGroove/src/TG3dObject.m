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
#import "Mixer.h"
#import "GraphView.h"

@interface TG3dObject () {
    PointPlayer * _ptPlayer;
    float _noteTimer;
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
    }
    return self;
}

-(id)wireUp
{
    self.settingsAreDirty = false;
    if( !_soundName )
        self.soundName = @"vibes";
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

#pragma mark sound stuff

-(void)play {}
-(void)pause {}
-(void)stop {}

-(void)setSoundName:(NSString *)soundName
{
    _soundName = soundName;
    self.sound = [[Mixer sharedInstance] getSound:soundName];
}

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
    [self playNoteAtPt:pt];
}

-(void)TapRecordGesture:(TapRecordGesture*)rg recordingDone:(PointRecorder *)recorder
{
    _ptPlayer = [recorder makePlayer];
    _noteTimer = 0;
}

-(void)playNoteAtPt:(GLKVector3)pt
{
    Sound * sound = self.sound;
    if( !sound )
        return; // not sure when this happens anymore
    int lo = sound.lowestPlayable;
    int hi = sound.highestPlayable;
    int note = lo + (int)( (hi-lo) * pt.y );
    [sound playNote:note forDuration:0.3];
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
    _noteTimer += dt;
    if( _ptPlayer && (_noteTimer > _ptPlayer.duration ) )
    {
        [self playNoteAtPt:_ptPlayer.next];
        _noteTimer = 0;
    }
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
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [self render:_fbo.width h:_fbo.height];
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
    NSMutableDictionary * snames = [NSMutableDictionary new];
    NSArray * keys = [[Mixer sharedInstance] getAllSoundNames];
    for( NSString * key in keys )
        snames[key] = key;
    
    SettingsDescriptor * sd;
    sd = [[SettingsDescriptor alloc]  initWithControlType: SC_Picker
                                               memberName: @("audioSoundName")
                                                labelText: @"Sound"
                                                  options: @{ @"values":snames,
                                                        @"target":self, @"key":@"soundName"}
                                             initialValue: self.soundName
                                                 priority: AUDIO_SETTINGS];
    
    return @[sd];
    
}

@end
