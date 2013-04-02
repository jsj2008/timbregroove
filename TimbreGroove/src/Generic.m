//
//  TGGenericElement.m
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
#define SKIP_GENERIC_DECLS
#import "Generic.h"
#import "GenericShader.h"
#import "MeshBuffer.h"
#import "Camera.h"
#import "Texture.h"
#import "AssetLoader.h"
#import "Light.h"

NSString const * kShaderFeatureColor = @"#define COLOR\n";
NSString const * kShaderFeatureNormal = @"#define NORMAL\n";
NSString const * kShaderFeatureTexture = @"#define TEXTURE\n";
NSString const * kShaderFeatureUColor = @"#define U_COLOR\n";
NSString const * kShaderFeatureTime =  @"#define TIME\n";
NSString const * kShaderFeatureDistort =  @"#define MESH_DISTORT\n";
NSString const * kShaderFeatureDistortTexture =  @"#define TEXTURE_DISTORT\n";
NSString const * kShaderFeaturePsychedelic =  @"#define PSYCHEDELIC\n";
NSString const * kShaderFeatureSpotFilter =  @"#define SPOT_FILTER\n";
NSString const * kShaderFeatureBones = @"#define BONES\n";

@interface GenericBase () {
@protected
    bool _enableMultipleTextures;
    bool _supportPrepare;
    bool _supportMeshBind;
    NSMutableArray * _buffers;
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
    if( buffer.drawable )
        [_buffers addObject:buffer];
    else
        [_buffers insertObject:buffer atIndex:0];
}


-(void)createBuffer{}
-(void)createTexture{}
-(void)createTextures{}

-(void)createShader
{
    NSMutableArray * features = [NSMutableArray new];
    [self getShaderFeatures:features];
    NSMutableString * strFeatures = [NSMutableString new];
    for( NSString * feature in features )
        [strFeatures appendString:feature];
    self.shader = [GenericShader shaderWithHeaders:strFeatures];
}

-(void)getShaderFeatures:(NSMutableArray *)putHere
{
    NSMutableArray * arr = [NSMutableArray new];
    for( MeshBuffer * buffer in _buffers )
        [arr addObjectsFromArray:buffer.indicesIntoShaderNames];

    for( NSNumber * num in arr )
    {
        GenericVariables svar = [num intValue];
        switch (svar) {
            case gv_acolor:
                [putHere addObject:kShaderFeatureColor];
                break;
            case gv_normal:
                [putHere addObject:kShaderFeatureNormal];
                break;
            case gv_uv:
                [putHere addObject:kShaderFeatureTexture];
                break;
            case gv_boneWeights:
                [putHere addObject:kShaderFeatureBones];
                break;
            default:
                break;
        }
    }
    
    if( [arr containsObject:@(gv_normal)] )
        if( !_light ) // how buried is this??
            _light = [Light new];

    if( _useColor )
        [putHere addObject:kShaderFeatureUColor];
    
    if( _timerType != kSTT_None )
        [putHere addObject:kShaderFeatureTime];
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
        // drawable meshes are (should be)
        // sorted last
        for( MeshBuffer * b in _buffers )
        {
            [b bind];
            if( b.drawable )
                [b draw];
        }
        
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
