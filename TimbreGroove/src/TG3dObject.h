//
//  TGElement.h
//  TimbreGroove
//
//  Created by victor on 12/13/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGTypes.h"
#import "Node.h"
#import "Gestures.h"

@class Camera;
@class Shader;
@class MeshBuffer;
@class FBO;
@class GraphView;

@interface TG3dObject : Node<TapRecordGestureReceiver> {
@protected
    Shader * _shader;
    NSTimeInterval _totalTime;
    NSTimeInterval _timer;
}

-(void)update:(NSTimeInterval)dt mixerUpdate:(MixerUpdate *)mixerUpdate;
-(void)render:(NSUInteger)w h:(NSUInteger)h;
-(void)renderToFBO;
-(void)renderToCaptureAtBufferLocation:(GLint)location;

@property (nonatomic) bool autoRenderChildren;
@property (nonatomic) bool interactive;

@property (nonatomic) NSTimeInterval totalTime;
@property (nonatomic) NSTimeInterval timer;

@property (nonatomic,strong) Camera  * camera;
@property (nonatomic,strong) Shader  * shader;
@property (nonatomic,strong) GLKView * view;
@property (nonatomic,strong) FBO     * fbo;

@property (nonatomic)        GLKVector3 position;
@property (nonatomic)        GLKVector3 rotation;
@property (nonatomic)        GLKVector3 scale;
@property (nonatomic)             float scaleXYZ;

-(id)   wireUp;
-(id)   wireUpWithViewSize:(CGSize)viewSize;

-(void) clean;
-(id)   settingsChanged;
@property (nonatomic) bool settingsAreDirty;

- (GLKMatrix4) modelView; // based on position/rotation/scale
- (GLKMatrix4) calcPVM;   // combine camera and model
- (NSString *) getShaderHeader;
- (NSArray *)  getSettings;
- (NSDictionary *)getParameters;

-(void)didAttachToView:(GraphView *)view;
-(void)didDetachFromView:(GraphView *)view;

@end
