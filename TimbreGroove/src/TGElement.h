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
@class TGViewController;

@interface TGElement : TGGraphNode {
@protected
    NSMutableArray      * _buffers;
    NSMutableDictionary * _textures;
}

-(void)update:(NSTimeInterval)dt;
-(void)render:(NSUInteger)w h:(NSUInteger)h;

-(void)addBuffer:(TGVertexBuffer *)buffer;

@property (nonatomic,strong) TGCamera * camera;
@property (nonatomic,strong) TGShader * shader;

@property (nonatomic)        GLKVector3 position;
@property (nonatomic)        GLKVector3 rotation;
@property (nonatomic)        GLKVector3 scale;
@property (nonatomic)             float scaleXYZ;

@property (nonatomic)      unsigned int phases;

-(GLKMatrix4) modelView;
-(GLKMatrix4) calcPVM;

#pragma mark - only for derived classes
-(void)attachTextures:(unsigned int)phase;

@end
