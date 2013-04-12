//
//  TGElement.h
//  TimbreGroove
//
//  Created by victor on 12/13/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGTypes.h"
#import "Node.h"

@class Camera;
@class Shader;
@class MeshBuffer;
@class FBO;
@class GraphView;
@class Scene;

@interface TG3dObject : Node {
@protected
    Shader * _shader;
    NSTimeInterval _totalTime;
    NSTimeInterval _timer;
    NSMutableArray * _parameters;
}

-(void)update:(NSTimeInterval)dt;
-(void)render:(NSUInteger)w h:(NSUInteger)h;
-(void)renderToFBO;
-(void)renderToCaptureAtBufferLocation:(GLint)location;

@property (nonatomic) bool interactive;

@property (nonatomic) NSTimeInterval totalTime;
@property (nonatomic) NSTimeInterval timer;

@property (nonatomic,strong) Camera    * camera;
@property (nonatomic,strong) Shader    * shader;
@property (nonatomic,strong) GraphView * view;
@property (nonatomic,strong) FBO       * fbo;

-(GraphView *)hasView;

@property (nonatomic)        GLKVector3 position;
@property (nonatomic)        GLKVector3 rotation;
@property (nonatomic)        GLKVector3 scale;
@property (nonatomic)             float scaleXYZ;

@property (nonatomic)        GLKVector3 rotationScale;

-(id)   wireUp;
-(id)   wireUpWithViewSize:(CGSize)viewSize;

-(void) clean;
-(id)   settingsChanged;
@property (nonatomic) bool settingsAreDirty;

- (GLKMatrix4) modelView; // based on position/rotation/scale
- (GLKMatrix4) calcPVM;   // combine camera and model

@property (nonatomic) bool disableStandardParameters;

- (void)getSettings:(NSMutableArray *)putHere;
- (void)getParameters:(NSMutableDictionary *)putHere;
- (void)getTriggerMap:(NSMutableArray *)putHere;
- (void)triggersChanged:(Scene *)scene;

@end
