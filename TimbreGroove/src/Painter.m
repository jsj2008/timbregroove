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
    Lights * _lights;
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
    [self setupLights];
    [self addShaderFeature:(PainterCamera *)self.camera];
    [self createShader]; // generic assumes materials & buffer exists
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

-(Lights *)lights
{
    Painter * e = self;
    
    while( e && e->_lights == nil )
        e = (Painter *)e.parent;
    
    return e ? e->_lights : nil;
}

-(void)setLights:(Lights *)lights
{
    Lights * oldLights = self.lights;
    if( oldLights )
        [self removeShaderFeature:oldLights];
    
    _lights = lights;
    
    [self addShaderFeature:lights];
}

-(void)setupLights
{
    if( !_lights )
    {
        Lights * lights = self.lights;
        if( lights )
            [self addShaderFeature:lights];
    }
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    if( !_buffers && !_shapes )
        return; // this can happen on container nodes
    
    Shader * shader = self.shader;
    
    [shader use];
    
    [shader prepareRender:self];
    
    if( _shaderFeatures )
        for( id<ShaderFeature> feature in _shaderFeatures )
            [feature bind:shader object:self];

    if( _buffers )
    {
        for(MeshBuffer * b in _buffers )
        {
            [b bind];
            if( b.drawable )
                [b draw];
        }
        for(MeshBuffer * b in _buffers )
            [b unbind];
    }
    
    if( _shapes )
        [self renderShapes:shader];

    if( _shaderFeatures )
        for( id<ShaderFeature> feature in _shaderFeatures )
            [feature unbind:shader];

}

-(void)renderShapes:(Shader *)shader
{
    for(PainterShape * shape in _shapes )
    {
        for(id<ShaderFeature> feature in shape->features)
            [feature bind:shader object:self];
        [shape->buffer bind];
        [shape->buffer draw];
        for(id<ShaderFeature> feature in shape->features)
            [feature unbind:shader];
    };
    
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
    
    for( id<ShaderFeature> feature in [self getAllFeatures] )
    {
        if( [feature respondsToSelector:@selector(getParameters:)] )
            [feature getParameters:putHere];
    }
}
@end
