//
//  TGElement.h
//  TimbreGroove
//
//  Created by victor on 12/13/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGTypes.h"
#import "TGGraphNode.h"

/*
 
    need a 'sub' element that shares resources:
      - buffer
      - shader
    with unique things like
      - texture
      - model matrix
 
 */
@class TGCamera;
@class TGShader;
@class TGVertexBuffer;
@class GLKView;

@interface TGElement : TGGraphNode

-(void)update:(NSTimeInterval)dt;
-(void)render:(NSUInteger)w h:(NSUInteger)h;

// called by capture for interactive objects
-(void)drawBufferToShader:(TGShader *)shader atLocation:(GLint)location;

@property (nonatomic,strong) TGCamera * camera;
@property (nonatomic,strong) TGShader * shader;
@property (nonatomic,strong) GLKView  * view;

@property (nonatomic)        GLKVector3 position;
@property (nonatomic)        GLKVector3 rotation;
@property (nonatomic)        GLKVector3 scale;
@property (nonatomic)             float scaleXYZ;

@property (nonatomic)              bool interactive;

-(GLKMatrix4) modelView;
-(GLKMatrix4) calcPVM;

@end
