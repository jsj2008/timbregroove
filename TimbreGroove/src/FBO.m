//
//  FBO.m
//  TimbreGroove
//
//  Created by victor on 12/28/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "FBO.h"

@interface FBO() { 
    GLuint _fbo;
}
@end
@implementation FBO

- (id) initWithWidth:(GLuint)width
              height:(GLuint)height
{
    return [self initWithWidth:width height:height type:0 format:0];
}

- (id) initWithWidth:(GLuint)width
              height:(GLuint)height
                type:(GLenum)type
              format:(GLenum)format
{
    _width = width;
    _height = height;
    
    GLuint texture;
    GLuint render;
    
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);

    // I'm told these are the only format/types that work on iOS
    
    //if( !format )
        format = GL_RGBA;
   // if( !type )
    type = GL_UNSIGNED_BYTE;
    
    glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, format, type, NULL);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    
    glGenRenderbuffers(1, &render);
    glBindRenderbuffer(GL_RENDERBUFFER, render);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
    
    glGenFramebuffers(1, &_fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, render);
    
#if DEBUG
    GLint fbs = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if(  fbs != GL_FRAMEBUFFER_COMPLETE )
    {
        NSLog(@"Framebuffer status blowed up: 0x%04X", fbs);
        return nil;
    }
#endif
    
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    return [super initWithGlTextureId:texture];
}

- (void)bindToRender
{
    glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
}

- (void)unbindFromRender
{
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

@end









