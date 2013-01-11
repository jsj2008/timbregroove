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
#import "SettingsVC.h"

static NSString * const _str_bakerShaderPicker = @"bakerShader";

static const char * __bakerShakerModes[] = {
    "BLUR_DOWN", "SOLARIZE", "BLEED_UP"
};

static const char *__bakeShakerNames[] = {
    "Blur me down", "Heat me up", "Burn me out"
};

static const float __bakeShakerTimes[] = {
    8.5f,           4.2f,         12.0f
};

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

+(NSDictionary *)getShaderModes
{
    return @{@(0):@(__bakeShakerNames[0]), @(1):@(__bakeShakerNames[1]),@(2):@(__bakeShakerNames[2])};
}

-(void)setMode:(int)mode
{
    _mode = mode;
    self.needsRewire = true;
}

-(id)wireUp
{
    [super wireUp];
    GLKView * glview = (GLKView *)(self.view.superview);
    GLint w = glview.drawableWidth;
    GLint h = glview.drawableHeight;
    _px = 1.0f / w;
    _py = 1.0f / h;
    GLKVector2 pixelSize = { _px, _py };
    [self.shader.locations write:@"u_pixelSize" type:TG_VECTOR2 data:&pixelSize];

    _uSampler2 = [self.shader.locations locationForName:@"u_sampSnap"];
    _uSampler1 = [self.shader.locations locationForName:@"u_sampXPix"];
    
    self.camera = [IdentityCamera new];

    _picture = [[Texture alloc] initWithFileName:@"aotk-ass-bare-512.tif"];
    _fbo1 = [[FBO alloc] initWithWidth:w height:h];
    _fbo2 = [[FBO alloc] initWithWidth:w height:h];
    _fbo3 = [[FBO alloc] initWithWidth:w height:h];

    [self setRefreshing:false];
    [self setRefreshing:true];

    return self;
}

-(void)setRefreshing:(bool)value
{
    _refreshing = value;
    [self.shader.locations write:@"u_refreshing" type:TG_BOOL data:&_refreshing];
    if( _refreshing )
    {
        _picture.uLocation = _uSampler1;
        self.fbo.uLocation = _uSampler2;
        [self replaceTextures:@[_picture,self.fbo]];
    }
    else
    {
        [self wireTexturesOne:_picture Two:_fbo2 fbo:_fbo1];
        [self renderToFBO];
    }
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
    NSString * header = [(@"#define ") stringByAppendingString:@(__bakerShakerModes[_mode])];
    self.shader = [[GenericShader alloc] initWithName:@"imageBaker" andHeader:header];
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
    _time += dt;    // frame rate
    _time2 += dt;   // fx duration
    
    if( _refreshing )
    {
        if( _time2 > 0.5 )
        {
            [self setRefreshing:false];
            _time2 = 0.0;
        }
        float f = _time2;
        [self.shader.locations write:@"u_timeDiff" type:TG_FLOAT data:&f];
    }
    else
    {
        if( _time > 0.1 )
        {
            if( _time2 > __bakeShakerTimes[_mode] )
            {
                [self setRefreshing:true];
                _time2 = 0.0;
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
                [self renderToFBO];
            }
            _time = 0.0;
        }
    }
}

-(NSArray *)getSettings
{
    NSArray * arr = [super getSettings];
    NSDictionary * shaders = [ImageBaker getShaderModes];
    
    SettingsDescriptor * sd;
    sd = [[SettingsDescriptor alloc]  initWithControlType: SC_Picker
                                               memberName: _str_bakerShaderPicker
                                                labelText: @"Effect"
                                                  options: @{@"values":shaders,
                                                          @"target":self, @"key":@"mode"}
                                             initialValue: @(_mode)
                                                 priority: SHADER_SETTINGS];
    
    return [arr arrayByAddingObject:sd];
    
}

@end