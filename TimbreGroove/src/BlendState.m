//
//  BlendState.m
//  TimbreGroove
//
//  Created by victor on 1/30/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "BlendState.h"

@interface BlendState() {
    GLboolean  _state;
    GLenum     _srcFactor;
    GLenum     _dstFactor;
    GLKVector4 _bColor;
    
    bool _factors;
    bool _color;
}
@end

@implementation BlendState

+(id)enable:(bool)enable srcFactor:(GLenum)srcF dstFactor:(GLenum)dstF bColor:(GLKVector4)color
{
    return [[BlendState alloc] initWithEnable:enable srcFactor:srcF dstFactor:dstF bColor:color];
}
+(id)enable:(bool)enable srcFactor:(GLenum)srcF dstFactor:(GLenum)dstF
{
    return [[BlendState alloc] initWithEnable:enable srcFactor:srcF dstFactor:dstF];
    
}
+(id)enable:(bool)enable
{
    return [[BlendState alloc] initWithEnable:enable];
}

-(id)initWithEnable:(bool)enable srcFactor:(GLenum)srcF dstFactor:(GLenum)dstF bColor:(GLKVector4)color
{
    if( (self = [super init] ) )
    {
        [self enable:enable];
        [self factors:srcF dst:dstF];
        glGetFloatv(GL_BLEND_COLOR, _bColor.v);
        _color = true;
        glBlendColor(color.r, color.g, color.b, color.a);
    }
    return self;
}

-(id)initWithEnable:(bool)enable srcFactor:(GLenum)srcF dstFactor:(GLenum)dstF;
{
    if( (self = [super init] ) )
    {
        [self enable:enable];
        [self factors:srcF dst:dstF];
    }
    return self;
}

-(id)initWithEnable:(bool)enable;
{
    if( (self = [super init] ) )
    {
        [self enable:enable];
    }
    return self;
}

-(void)restore
{
    if( _state )
        glEnable(GL_BLEND);
    else
        glDisable(GL_BLEND);
    if( _factors )
        glBlendFunc(_srcFactor, _dstFactor);
    if( _color)
        glBlendColor(_bColor.r, _bColor.g, _bColor.b, _bColor.a);
}

-(void)enable:(bool)enable
{
    _state = glIsEnabled(GL_BLEND);
    if( enable )
        glEnable(GL_BLEND);
    else
        glDisable(GL_BLEND);
}

-(void)factors:(GLenum)src dst:(GLenum)dst
{
    glGetIntegerv(GL_BLEND_SRC, (GLint *)&_srcFactor);
    glGetIntegerv(GL_BLEND_DST, (GLint *)&_dstFactor);
    _factors = true;
    glBlendFunc(src, dst);
}


@end
