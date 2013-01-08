//
//  TestElement.m
//  TimbreGroove
//
//  Created by victor on 1/5/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "ImageBaker.h"
#import "GenericShader.h"
#import "Camera.h"
#import "FBO.h"
#import "TrackView.h"

@interface ImageBaker() {
    Texture * _picture;
    FBO * _fbo1;
    FBO * _fbo2;
    FBO * _fbo3;
    
    NSTimeInterval _time;
    NSTimeInterval _time2;

    float _px;
    float _py;
    
    GLint _uSampler1;
    GLint _uSampler2;
    
    bool _refreshing;
}

@end
@implementation ImageBaker

-(id)initWithObject:(id)view
{
    self = [super init];
    if( !self )
        return nil;
    
    GLKView * glview = (GLKView *)(((TrackView *)view).superview);
    GLint w = glview.drawableWidth;
    GLint h = glview.drawableHeight;
    _px = 1.0f / w;
    _py = 1.0f / h;
    GLKVector2 pixelSize = { _px, _py };
    [self.shader.locations write:@"u_pixelSize" type:TG_VECTOR2 data:&pixelSize];

    _uSampler1 = [self.shader.locations locationForName:@"u_sampler"];
    _uSampler2 = [self.shader.locations locationForName:@"u_samplerSnap"];
    
    self.camera = [IdentityCamera new];

    _picture = [[Texture alloc] initWithFileName:@"aotk-ass-bare-512.tif"];
    _fbo1 = [[FBO alloc] initWithWidth:w height:h];
    _fbo2 = [[FBO alloc] initWithWidth:w height:h];
    _fbo3 = [[FBO alloc] initWithWidth:w height:h];
    
    [self setRefreshing:true];
    self.fbo = _fbo1;
    /*
    [self wireTexturesOne:_picture Two:_fbo3 fbo:_fbo1];
    [self renderToFBO];
    */

    
    return self;
}

-(void)setRefreshing:(bool)value
{
    _refreshing = value;
    [self.shader.locations write:@"u_refreshing" type:TG_BOOL data:&_refreshing];
}

-(void)wireTexturesOne:(Texture *)one Two:(Texture *)two fbo:(FBO *)fbo
{
    one.uLocation = _uSampler1;
    two.uLocation = _uSampler2;
    [self replaceTextures:@[one,two]];
    self.fbo = fbo;
}

-(void)createShader
{
    self.shader = [[GenericShader alloc] initWithName:@"imageBaker" andHeader:@"#define BLEED_UP"];
}

-(void)createBuffer
{
    [self createBufferDataByType:@[@(sv_pos),@(sv_uv)] numVertices:6 numIndices:0];
}

-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
{
    static float v[6*(3+2)] = {
        //   x   y  z    u    v
        -1, -1, 0,   0,   0,
        -1,  1, 0,   0,   1,
        1, -1, 0,   1,   0,
        
        -1,  1, 0,   0,   1,
        1,  1, 0,   1,   1,
        1, -1, 0,   1,   0
    };
    
    memcpy(vertextData, v, sizeof(v));
}

-(void)getTextureLocations
{
    // knock out default behavoir
}

-(void)update:(NSTimeInterval)dt
{
    _time += dt;
    _time2 += dt;
    NSTimeInterval check = 0;
    if( _time > 0.1 )
    {
        if( _refreshing )
        {
            
            if( self.fbo == _fbo1 || self.fbo == _fbo3 )
            {
                [self wireTexturesOne:_fbo1 Two:_picture fbo:_fbo2];
            }
            else
            {
                [self wireTexturesOne:_fbo2 Two:_picture fbo:_fbo1];
            }

            check = 3.5;
            
            float timeDiff = check - (_time2*1.2);
            if( timeDiff < 0 )
                timeDiff = 0;
            [self.shader.locations write:@"u_timeDiff" type:TG_FLOAT data:&timeDiff];            
        }
        else
        {
            if( self.fbo == _fbo1 )
            {
                [self wireTexturesOne:_fbo1 Two:_fbo2 fbo:_fbo3];
            }
            else if ( self.fbo == _fbo2 )
            {
                [self wireTexturesOne:_fbo2 Two:_fbo3 fbo:_fbo1];
            }
            else
            {
                [self wireTexturesOne:_fbo3 Two:_fbo1 fbo:_fbo2];
            }
            
            check = 10.0;
        }
        [self renderToFBO];
        
        if( _time2 > check  )
        {
            [self setRefreshing:!_refreshing];
            _time2 = 0.0;
        }
        

        _time = 0;
    }
}
@end
