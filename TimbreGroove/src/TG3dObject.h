//
//  TGElement.h
//  TimbreGroove
//
//  Created by victor on 12/13/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGTypes.h"
#import "Node.h"

/*
 
    need a 'sub' element that shares resources:
      - buffer
      - shader
    with unique things like
      - texture
      - model matrix
 
 */
@class Camera;
@class Shader;
@class MeshBuffer;
@class GLKView;
@class FBO;

@interface TG3dObject : Node

-(void)update:(NSTimeInterval)dt;
-(void)render:(NSUInteger)w h:(NSUInteger)h;
-(void)renderToFBO;
-(void)renderToFBOWithClear:(bool)clear;
-(void)renderToCapture:(Shader *)shader atLocation:(GLint)location;

@property (nonatomic,strong) Camera   * camera;
@property (nonatomic,strong) Shader   * shader;
@property (nonatomic,strong) GLKView  * view;
@property (nonatomic,strong) FBO      * fbo;

@property (nonatomic)        GLKVector3 position;
@property (nonatomic)        GLKVector3 rotation;
@property (nonatomic)        GLKVector3 scale;
@property (nonatomic)             float scaleXYZ;

-(GLKMatrix4) modelView;
-(GLKMatrix4) calcPVM;

- (NSString *)getShaderHeader;
- (Camera *)ownCamera; // hmmm

@end
