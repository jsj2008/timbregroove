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
@class GLKView;
@class FBO;
@class View;

@interface TG3dObject : Node {
@protected
    Shader * _shader;
}

-(void)update:(NSTimeInterval)dt;
-(void)render:(NSUInteger)w h:(NSUInteger)h;
-(void)renderToFBO;
-(void)renderToCaptureAtBufferLocation:(GLint)location;

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

-(void)play;
-(void)pause;
-(void)stop;

/*
  Do as little as humanly possible in init
  Make initialization params into properties into 2 groups:
     - tweakable by 'settings' page which might trigger a 'rewire'
     - tweakable by gesture ('runtime' settable)
 
 First time init for default TG3dObject:
 
     alloc/init
     node.view = set to TrackView:GLKView
     placed in view.graph
     params deserialized from plist (or store to be named)
     [node wireUp];

 after that the system should be able to simply call 'rewire'
 when a propery has changed.
 
 Default implementation of rewire:
    - clean children
    - clean (wipe buffers & textures)
    - wireUp
 */

-(id)   wireUp;
-(void) clean;
-(id)   rewire;
@property (nonatomic) bool needsRewire;

- (GLKMatrix4) modelView; // based on position/rotation/scale
- (GLKMatrix4) calcPVM;   // combine camera and model
- (NSString *) getShaderHeader;
- (Camera *)   ownCamera; // hmmm
- (NSArray *)  getSettings;

@end
