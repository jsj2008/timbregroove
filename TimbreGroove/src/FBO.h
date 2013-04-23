//
//  FBO.h
//  TimbreGroove
//
//  Created by victor on 12/28/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Material.h"

@class Node3d;

@interface FBO : Texture
@property (nonatomic) GLuint width;
@property (nonatomic) GLuint height;

- (id) initWithWidth:(GLuint)width
              height:(GLuint)height;

-(id)initWithObject:(Node3d *)object
              width:(GLuint)width
             height:(GLuint)height;

- (void)bindToRender;
- (void)unbindFromRender;

@property (nonatomic) GLKVector4 clearColor;
@property (nonatomic) bool allowDepthCheck;

//deprecated
- (id) initWithWidth:(GLuint)width
              height:(GLuint)height
                type:(GLenum)type    // 0 means RGBA
              format:(GLenum)format; // 0 means UNSIGNED BYTE


@end
