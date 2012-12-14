//
//  TGElement.h
//  TimbreGroove
//
//  Created by victor on 12/13/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGGraphNode.h"

@class TGCamera;
@class TGShader;
@class TGVertexBuffer;
@class TGViewController;

@interface TGElement : TGGraphNode

-(void)update:(TGViewController *)vc;
-(void)render:(TGViewController *)vc;

-(void)addBuffer:(TGVertexBuffer *)buffer;

@property (nonatomic,strong) TGCamera * camera;
@property (nonatomic,strong) TGShader * shader;

@property (nonatomic)        GLKVector3 position;
@property (nonatomic)        GLKVector3 rotation;

@property (nonatomic)      unsigned int phases;

-(GLKMatrix4) modelView;

// derived classes
-(void)writeUniforms:(unsigned int)phase;

@end
