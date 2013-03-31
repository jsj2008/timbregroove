//
//  BlendState.m
//  TimbreGroove
//
//  Created by victor on 1/30/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "State.h"

@interface DepthTestState() {
    GLboolean  _state;
    bool _restored;
}
@end

@implementation DepthTestState

+(id)enable:(bool)enable
{
    return [[DepthTestState alloc] initWithEnable:enable];
}

-(id)initWithEnable:(bool)enable
{
    self = [super init];
    if( self )
    {
        [self enable:enable];
    }
    return self;
}

-(void)dealloc
{
    if( !_restored )
        [self restore];
}

-(void)enable:(bool)enable
{
    _state = glIsEnabled(GL_DEPTH_TEST);
    if( enable )
        glEnable(GL_DEPTH_TEST);
    else
        glDisable(GL_DEPTH_TEST);
    _restored = false;
}

-(void)restore
{
    if( _state )
        glEnable(GL_DEPTH_TEST);
    else
        glDisable(GL_DEPTH_TEST);
    _restored = true;
}

@end

@interface BlendState() {
    GLboolean  _state;
    GLenum     _srcFactor;
    GLenum     _dstFactor;
    GLKVector4 _bColor;
    
    bool _factors;
    bool _color;
    
    bool _restored;
}
@end

@implementation BlendState

+(id)enable:(bool)enable
{
    return [[BlendState alloc] initWithEnable:enable];
}
+(id)enable:(bool)enable srcFactor:(GLenum)srcF dstFactor:(GLenum)dstF
{
    return [[BlendState alloc] initWithEnable:enable srcFactor:srcF dstFactor:dstF];
    
}
+(id)enable:(bool)enable srcFactor:(GLenum)srcF dstFactor:(GLenum)dstF bColor:(GLKVector4)color
{
    return [[BlendState alloc] initWithEnable:enable srcFactor:srcF dstFactor:dstF bColor:color];
}

-(id)initWithEnable:(bool)enable;
{
    if( (self = [super init] ) )
    {
        [self enable:enable];
    }
    return self;
}
-(id)initWithEnable:(bool)enable srcFactor:(GLenum)srcF dstFactor:(GLenum)dstF;
{
    if( (self = [super init] ) )
    {
        [self enable:enable srcFactor:srcF dstFactor:dstF];
    }
    return self;
}
-(id)initWithEnable:(bool)enable srcFactor:(GLenum)srcF dstFactor:(GLenum)dstF bColor:(GLKVector4)color
{
    if( (self = [super init] ) )
    {
        [self enable:enable srcFactor:srcF dstFactor:dstF bColor:color];
    }
    return self;
}

-(void)dealloc
{
    if( !_restored )
        [self restore];
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
    
    _restored = true;
}

-(void)color:(GLKVector4)color
{
    glGetFloatv(GL_BLEND_COLOR, _bColor.v);
    _color = true;
    glBlendColor(color.r, color.g, color.b, color.a);
    _restored = false;
}

-(void)factors:(GLenum)src dst:(GLenum)dst
{
    glGetIntegerv(GL_BLEND_SRC, (GLint *)&_srcFactor);
    glGetIntegerv(GL_BLEND_DST, (GLint *)&_dstFactor);
    _factors = true;
    glBlendFunc(src, dst);
    _restored = false;
}

-(void)enable:(bool)enable
{
    _state = glIsEnabled(GL_BLEND);
    _factors = false;
    _color = false;
    if( enable )
        glEnable(GL_BLEND);
    else
        glDisable(GL_BLEND);
    _restored = false;
}

-(void)enable:(bool)enable srcFactor:(GLenum)srcF dstFactor:(GLenum)dstF
{
    [self enable:enable];
    if( enable )
        [self factors:srcF dst:dstF];
}

-(void)enable:(bool)enable srcFactor:(GLenum)srcF dstFactor:(GLenum)dstF bColor:(GLKVector4)color
{
    [self enable:enable];
    if( enable )
    {
        [self color:color];
        [self factors:srcF dst:dstF];
    }
}

@end
