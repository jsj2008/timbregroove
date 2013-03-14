//
//  BlendState.h
//  TimbreGroove
//
//  Created by victor on 1/30/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlendState : NSObject

+(id)enable:(bool)enable;
+(id)enable:(bool)enable srcFactor:(GLenum)srcF dstFactor:(GLenum)dstF;
+(id)enable:(bool)enable srcFactor:(GLenum)srcF dstFactor:(GLenum)dstF bColor:(GLKVector4)color;
-(id)initWithEnable:(bool)enable;
-(id)initWithEnable:(bool)enable srcFactor:(GLenum)srcF dstFactor:(GLenum)dstF;
-(id)initWithEnable:(bool)enable srcFactor:(GLenum)srcF dstFactor:(GLenum)dstF bColor:(GLKVector4)color;
-(void)restore;
-(void)color:(GLKVector4)color;
-(void)factors:(GLenum)src dst:(GLenum)dst;
-(void)enable:(bool)enable;
-(void)enable:(bool)enable srcFactor:(GLenum)srcF dstFactor:(GLenum)dstF;
-(void)enable:(bool)enable srcFactor:(GLenum)srcF dstFactor:(GLenum)dstF bColor:(GLKVector4)color;
@end

@interface DepthTestState : NSObject

+(id)enable:(bool)enable;

-(id)initWithEnable:(bool)enable;
-(void)enable:(bool)enable;
-(void)restore;
@end
