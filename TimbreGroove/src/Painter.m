//
//  TGGenericElement.m
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
#define SKIP_GENERIC_DECLS
#import "Painter.h"
#import "GenericShader.h"
#import "MeshBuffer.h"
#import "PainterCamera.h"
#import "Material.h"
#import "AssetLoader.h"
#import "Light.h"

NSString const * kShaderFeatureColor           = @"#define COLOR\n";
NSString const * kShaderFeatureNormal          = @"#define NORMAL\n";
NSString const * kShaderFeatureTexture         = @"#define TEXTURE\n";
NSString const * kShaderFeatureTime            = @"#define TIME\n";
NSString const * kShaderFeatureBones           = @"#define BONES\n";
NSString const * kShaderFeatureDistortTexture  = @"#define TEXTURE_DISTORT\n";

@interface PainterShape : NSObject {
    @public
    MeshBuffer * buffer;
    NSArray * features;
}
@end
@implementation PainterShape
@end

@implementation Painter {
    NSMutableArray * _buffers;
    NSMutableArray * _shaderFeatures;
    NSMutableArray * _shapes;
    bool _wiredUp;
    bool _cameredUp;
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
    if( !_wiredUp )
    {
        [super wireUp];
        [self createBuffer];
        [self createShader]; // generic assumes materials & buffer exists
        _wiredUp = true;
    }
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

-(NSArray *)getAllFeatures
{
    NSMutableArray * allFeatures = [NSMutableArray arrayWithArray: _shaderFeatures ? _shaderFeatures : @[]];
    if( _shapes )
        [_shapes apply:^(PainterShape *shape) { if( shape->features ) [allFeatures addObjectsFromArray:shape->features]; }];
    return allFeatures;
}

-(NSArray *)getAllBuffers
{
    NSMutableArray * allBuffers = [NSMutableArray arrayWithArray: _buffers ? _buffers : @[]];
    if( _shapes )
        [_shapes apply:^(PainterShape *shape) { [allBuffers addObject:shape->buffer]; }];
    return allBuffers;
}

-(void)setShaderOnFeatures:(NSArray *)features shader:(Shader *)shader
{
    if( !shader )
        return;
    [features apply:^(id<ShaderFeature> feature) {
        if( [feature respondsToSelector:@selector(setShader:)] )
            [feature setShader:shader];
    }];
}

-(void)createShader
{
    Shader * shader = [GenericShader shaderWithHeaders:[self getShaderDefines]];
    self.shader = shader;
    
    [_buffers each:^(MeshBuffer * buffer) { [buffer getLocations:shader]; }];

    [self setShaderOnFeatures:[self getAllFeatures] shader:shader];
    
    if( _shapes )
        [_shapes each:^(PainterShape * shape) { [shape->buffer getLocations:shader]; }];
}

-(void)getShaderFeatureNames:(NSMutableArray *)putHere
{    
    [[self getAllFeatures] apply:^(id<ShaderFeature> feature) {
        if( [feature respondsToSelector:@selector(getShaderFeatureNames:)] )
           [feature getShaderFeatureNames:putHere];
    }];
        
    NSMutableArray * arr = [NSMutableArray new];
    [[self getAllBuffers] apply:^(MeshBuffer *buffer) { [arr addObjectsFromArray:buffer.indicesIntoShaderNames]; }];

    for( NSNumber * num in arr )
    {
        GenericVariables svar = [num intValue];
        switch (svar) {
            case gv_acolor:
                [putHere addObject:kShaderFeatureColor];
                break;
            case gv_normal:
                [putHere addObject:kShaderFeatureNormal];
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
    [self setShaderOnFeatures:@[feature] shader:[self hasShader]];
}

-(void)removeShaderFeature:(id<ShaderFeature>)feature
{
    [_shaderFeatures removeObject:feature];
}

-(void)addShape:(MeshBuffer *)buffer
       features:(NSArray *)shaderFeatures
{
    if( !_shapes )
        _shapes = [NSMutableArray new];
    PainterShape * is = [PainterShape new];
    is->buffer = buffer;
    is->features = shaderFeatures;
    [_shapes addObject:is];
    [self setShaderOnFeatures:shaderFeatures shader:[self hasShader]];
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    if( !_wiredUp )
        [self wireUp];
    
    if( !_cameredUp )
    {
        [self addShaderFeature:(PainterCamera *)self.camera];
        _cameredUp = true;
    }
    
    Shader * shader = self.shader;
    
    [shader use];
    
    [shader prepareRender:self];
    
    if( _shaderFeatures )
        [_shaderFeatures each:^(id<ShaderFeature> feature) { [feature bind:shader object:self]; }];

    if( _buffers )
    {
        [_buffers each:^(MeshBuffer * b) {
            [b bind];
            if( b.drawable )
                [b draw];
        }];
        [_buffers each:^(MeshBuffer * b) {
            [b unbind];
        }];
    }
    
    if( _shapes )
        [self renderShapes:shader];

    if( _shaderFeatures )
        [_shaderFeatures each:^(id<ShaderFeature> feature) { [feature unbind:shader]; }];

}

-(void)renderShapes:(Shader *)shader
{
    [_shapes each:^(PainterShape * shape) {
        if( shape->features )
            [shape->features each:^(id<ShaderFeature> feature) { [feature bind:shader object:self]; }];
        [shape->buffer bind];
        [shape->buffer draw];
        if( shape->features )
            [shape->features each:^(id<ShaderFeature> feature) { [feature unbind:shader]; }];
    }];
    
}
-(void)renderToCaptureAtBufferLocation:(GLint)location
{
    [[self getAllBuffers] each:^(MeshBuffer * buffer) {
        if( buffer.drawable )
        {
            [buffer bindToTempLocation:location];
            [buffer draw];
            [buffer unbind];
        }
    }];
}

- (void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];
    
    [[self getAllFeatures] each:^(id<ShaderFeature> feature) {
        if( [feature respondsToSelector:@selector(getParameters:)] )
            [feature getParameters:putHere];
    }];
}
@end
