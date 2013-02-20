//
//  TGGenericElement.m
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Generic.h"
#import "GenericShader.h"
#import "MeshBuffer.h"
#import "Camera.h"
#import "Texture.h"
#import "AssetLoader.h"
#import "Light.h"

@interface GenericBase () {
@protected
    bool _enableMultipleTextures;
    bool _supportPrepare;
    bool _supportMeshBind;
}

@end

@implementation GenericBase

-(void)clean
{
    [super clean];
    _buffers = nil;
}

-(id)wireUp
{
    [super wireUp];
    if( _enableMultipleTextures )
        [self createTextures];
    else
        [self createTexture];
    [self createBuffer];
    [self createShader]; // generic assumes on buffer exists
    [self getBufferLocations];
    [self getTextureLocations];
    [self configureLighting];
    [self setSounds];
    return self;
}

-(void)setShader:(Shader *)shader
{
    [super setShader:shader];
    
    _supportMeshBind = [shader respondsToSelector:@selector(location:)];
    _supportPrepare  = [shader respondsToSelector:@selector(prepareRender:)];
}

#pragma mark -
#pragma mark Initialization sequence
#pragma mark -

-(void)addBuffer:(MeshBuffer *)buffer
{
    if( !_buffers )
        _buffers = [NSMutableArray new];
    [_buffers addObject:buffer];
}


-(void)createBuffer{}
-(void)createTexture{}
-(void)createTextures{}
-(void)setSounds{}

-(void)createShader
{
    self.shader = [GenericShader shaderWithHeaders:[self getShaderHeader]];
}

- (NSString *)getShaderHeader
{
    NSMutableArray * arr = [NSMutableArray new];
    for( MeshBuffer * buffer in _buffers )
        [arr addObjectsFromArray:buffer.indicesIntoShaderNames];
    
    if( [arr containsObject:@(gv_normal)] )
        if( !_light ) // how buried is this??
            _light = [Light new];

    if( _useColor )
       [arr addObject:@(gv_ucolor)];
    
    return [Generic getShaderHeaderWithIndicesIntoName:arr];
}

+(NSString *)getShaderHeaderWithIndicesIntoName:(NSArray *)arr
{
    NSString * pre = @"";
    
    for( NSNumber * num in arr )
    {
        GenericVariables svar = [num intValue];
        NSString * ns;
        switch (svar) {
            case gv_acolor:
                ns = @"#define COLOR\n";
                break;
            case gv_normal:
                ns = @"#define NORMAL\n";
                break;
            case gv_uv:
                ns = @"#define TEXTURE\n";
                break;
            case gv_ucolor:
                ns = @"#define U_COLOR\n";
            default:
                break;
        }
        if(ns)
            pre = [pre stringByAppendingString:ns];
    }
    
    return pre;
}


-(void)configureLighting
{
}

#pragma mark -
#pragma mark Uniform properties
#pragma mark -

-(void)getTextureLocations
{
}


-(void)getBufferLocations
{
    if( _supportMeshBind )
        for( MeshBuffer * buffer in _buffers )
            [buffer getLocations:self.shader];
}

-(void)setColor:(GLKVector4)color
{
    _color = color;
    _useColor = true;
}

#pragma mark -
#pragma mark Per frame
#pragma mark -

/*
-(void)update:(NSTimeInterval)dt
{
}
*/

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    Shader * shader = self.shader;
    
    [shader use];
    
    if( _supportPrepare )
        [shader prepareRender:self];

    [self bindTextures:true];
    
    if( [_buffers count] == 1 )
    {
        MeshBuffer * b = _buffers[0];
        [b bind];
        [b draw];
        [b unbind];
    }
    else
    {
        for( MeshBuffer * b in _buffers )
            [b bind];

        for( MeshBuffer * b in _buffers )
            if( b.drawable )
                [b draw];
        
        for( MeshBuffer * b in _buffers )
            [b unbind];
    }
    [self bindTextures:false];
}

-(void)renderToCaptureAtBufferLocation:(GLint)location
{
    MeshBuffer * buffer = _buffers[0];
    [buffer bindToTempLocation:location];
    [buffer draw];
    [buffer unbind];
}

-(void)bindTextures:(bool)bind
{
}

@end

@interface Generic() {
    Texture * _texture;
    AssetLoader * _ati;
}
@end

@implementation Generic

-(void)clean
{
    [super clean];
    _texture = nil;
}

-(void)createTexture
{
    
}

-(void)getTextureLocations
{
    if( _texture )
    {
        Shader * shader = self.shader;
        _texture.uLocation = [shader location:gv_sampler];
    }
}

-(void)bindTextures:(bool)bind
{
    if( _texture )
    {
        if( bind )
            [_texture bind:0];
        else
            [_texture unbind];
    }
    
}

-(void)setTextureFileName:(id)textureFileName
{
    _textureFileName = textureFileName;
    if( [textureFileName isKindOfClass:[NSURL class]] )
    {
        _ati = [[AssetToImage alloc] initWithURL:textureFileName andTarget:self andKey:@"textureImage"];
    }
    else
    {
        self.texture = [[Texture alloc] initWithFileName:_textureFileName];
    }
}

// be careful not to call this setter while
// another part of the code triggers the AssetToImage
// call above
-(void)setTextureImage:(UIImage *)image
{
    self.texture = [[Texture alloc] initWithImage:image];
    _ati = nil;
}

-(Texture *)texture
{
    return _texture;
}

-(void)setTexture:(Texture *)texture
{
    _texture = texture;
}

-(bool)hasTexture
{
    return _texture != nil;
}


@end


@interface GenericMultiTextures () {
    NSMutableArray * _textures;
}
@end

@implementation GenericMultiTextures

-(void)clean
{
    [super clean];
    _textures = nil;
}

-(id)wireUp
{
    _enableMultipleTextures = true;
    return [super wireUp];
}

-(void)createTextures
{
    
}

-(void)bindTextures:(bool)bind
{
    int target = 0;
    for( Texture * t in _textures )
    {
        if( bind )
        {
            [t bind:target];
            ++target;
        }
        else
        {
            [t unbind];
        }
    }
}

-(void)replaceTextures:(NSArray *)textures
{
    _textures = [textures mutableCopy];
    [self getTextureLocations];
}

-(void)addTextureObject:(Texture *)texture
{
    if( !_textures )
        _textures = [NSMutableArray new];
    [_textures addObject:texture];
}

-(bool)hasTexture
{
    return [_textures count];
}

@end
