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
#import "GenericCamera.h"
#import "Material.h"
#import "AssetLoader.h"
#import "Light.h"

NSString const * kShaderFeatureColor           = @"#define COLOR\n";
NSString const * kShaderFeatureNormal          = @"#define NORMAL\n";
NSString const * kShaderFeatureTexture         = @"#define TEXTURE\n";
NSString const * kShaderFeatureUColor          = @"#define U_COLOR\n";
NSString const * kShaderFeatureTime            = @"#define TIME\n";
NSString const * kShaderFeatureDistortTexture  = @"#define TEXTURE_DISTORT\n";
NSString const * kShaderFeaturePsychedelic     = @"#define PSYCHEDELIC\n";
NSString const * kShaderFeatureSpotFilter      = @"#define SPOT_FILTER\n";
NSString const * kShaderFeatureBones           = @"#define BONES\n";
NSString const * kShaderFeaturePhongLighting   = @"#define PHONG_LIGHTING\n";
NSString const * kShaderFeatureLambertLighting = @"#define LAMBERT_LIGHTING\n";
NSString const * kShaderFeatureAmbientLighting = @"#define AMBIENT_LIGHTING\n";

@interface IndexShape : NSObject {
    @public
    MeshBuffer * indexBuffer;
    NSArray * features;
}
@end
@implementation IndexShape
@end

@implementation Generic {
    NSMutableArray * _buffers;
    NSMutableArray * _shaderFeatures;
    NSMutableArray * _shapes;
}

-(id)init
{
    self = [super init];
    if( self )
    {
        _lights = [[Lights alloc] initWithObject:self];
        [self addShaderFeature:_lights];
    }
    return self;
}
-(void)clean
{
    [super clean];
    _buffers = nil;
}

-(id)wireUp
{
    [super wireUp];
    [self createBuffer];
    [self createShader]; // generic assumes materials & buffer exists
    GenericCamera * camera = (GenericCamera *)self.camera;
    [self addShaderFeature:camera];
    return self;
}

-(void)createBuffer
{
}

-(NSString *)getShaderDefines
{
    NSMutableArray * _featureNames = [NSMutableArray new];
    [self getShaderFeatureNames:_featureNames];
    
    NSArray * featureNames = [[_featureNames unique] sortedArrayUsingSelector:@selector(compare:)];
    return [featureNames reduce:@"" withBlock:^id(NSString *str, id obj) {
        return [str stringByAppendingString:obj];
    }];
    
}
-(void)createShader
{
    Shader * shader = [GenericShader shaderWithHeaders:[self getShaderDefines]];
    self.shader = shader;
    
    [_buffers each:^(MeshBuffer * buffer) { [buffer getLocations:shader]; }];

    if( _shaderFeatures )
        [_shaderFeatures each:^(id<ShaderFeature> feature) { [feature setShader:shader]; }];
    
    if( _shapes )
        [_shapes each:^(IndexShape * shape) { [shape->indexBuffer getLocations:shader]; }];
}

-(void)getShaderFeatureNames:(NSMutableArray *)putHere
{
    if( _shaderFeatures )
        [_shaderFeatures apply:^(id<ShaderFeature> feature) { [feature getShaderFeatureNames:putHere]; }];
    
    if( _shapes )
        [_shapes apply:^(IndexShape *shape) {
            [shape->features apply:^(id<ShaderFeature> feature) { [feature getShaderFeatureNames:putHere]; }];
        }];
        
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
            case gv_boneWeights:
                [putHere addObject:kShaderFeatureBones];
                break;
            default:
                break;
        }
    }
}

-(void)addBuffer:(MeshBuffer *)buffer
{
    if( !_buffers )
        _buffers = [NSMutableArray new];
    if( buffer.drawable )
        [_buffers addObject:buffer];
    else
        [_buffers insertObject:buffer atIndex:0];
}


-(void)addShaderFeature:(id<ShaderFeature>)feature
{
    if( !_shaderFeatures )
        _shaderFeatures = [NSMutableArray new];
    [_shaderFeatures addObject:feature];
    Shader * hasShader = [self hasShader];
    if( hasShader )
       [feature setShader:hasShader];
    
}

-(void)removeShaderFeature:(id<ShaderFeature>)feature
{
    [_shaderFeatures removeObject:feature];
}

-(void)addIndexShape:(MeshBuffer *)indexBuffer
            features:(NSArray *)shaderFeatures
{
    if( !_shapes )
        _shapes = [NSMutableArray new];
    IndexShape * is = [IndexShape new];
    is->indexBuffer = indexBuffer;
    is->features = shaderFeatures;
    [_shapes addObject:is];
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    Shader * shader = self.shader;
    
    [shader use];
    
    [shader prepareRender:self];
    
    if( _shaderFeatures )
    {
        // don't do each:block here b/c of threading concerns
        for( id<ShaderFeature> feature in _shaderFeatures )
            [feature bind:shader object:self];
            
    }

    // drawable meshes are (should be)
    // sorted last
    for( MeshBuffer * b in _buffers )
    {
        [b bind];
        if( b.drawable )
            [b draw];
    }
    
    if( _shapes )
    {
        for( IndexShape * shape in _shapes )
        {
            if( shape->features )
            {
                for( id<ShaderFeature> feature in shape->features )
                    [feature bind:shader object:self];
            }
            [shape->indexBuffer bind];
            [shape->indexBuffer draw];
            if( shape->features )
            {
                for( id<ShaderFeature> feature in shape->features )
                    [feature unbind:shader];
            }
        }
    }
    
    for( MeshBuffer * b in _buffers )
        [b unbind];
    
    if( _shaderFeatures )
    {
        // don't do each:block here b/c of threading concerns
        for( id<ShaderFeature> feature in _shaderFeatures )
            [feature unbind:shader];
    }
}

-(void)renderToCaptureAtBufferLocation:(GLint)location
{
    for( MeshBuffer * buffer in _buffers )
    {
        if( buffer.drawable )
        {
            [buffer bindToTempLocation:location];
            [buffer draw];
            [buffer unbind];            
        }
    }
}


@end
