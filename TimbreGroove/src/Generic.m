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


-(void)createBuffer
{
    
}

-(void)addBuffer:(MeshBuffer *)buffer
{
    if( !_buffers )
        _buffers = [NSMutableArray new];
    [_buffers addObject:buffer];
}


-(void)createTexture
{
}

-(void)createTextures
{
}


-(void)createShader
{
    self.shader = [GenericShader shaderWithHeaders:[self getShaderHeader]];
}

- (NSString *)getShaderHeader
{
    NSMutableArray * arr = [NSMutableArray new];
    for( MeshBuffer * buffer in _buffers )
        [arr addObjectsFromArray:buffer.indicesIntoShaderNames];

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
                _lighting = true; // how buried is this??
                ns = @"#define NORMAL\n";
                break;
            case gv_uv:
                ns = @"#define TEXTURE\n";
                break;
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
    self.lightDir = GLKVector3Make(0, 0.5, 0);
    self.dirColor = GLKVector3Make(1, 1, 1);
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

-(void)update:(NSTimeInterval)dt
{
    // update model and camera matrix here
    // so children can adjust accordingly
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    Shader * shader = self.shader;
    
    [shader use];
    
    if( _supportPrepare )
        [shader prepareRender:self];

    [self bindTextures:true];
    
    for( MeshBuffer * b in _buffers )
    {
        [b bind];
        [b draw];
        [b unbind];
    }
    
    [self bindTextures:false];
}

-(void)bindTextures:(bool)bind
{
}

// capture hack
-(void)renderToCaptureAtBufferLocation:(GLint)location
{
    for( MeshBuffer * buffer in _buffers )
    {
        if( [buffer bindToTempLocation:location] )
        {
            [buffer draw];
            break; // we assume there is only one 'position' buffer.
        }
    }
    
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
