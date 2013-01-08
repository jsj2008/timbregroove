//
//  TGGenericElement.m
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGGeneric3dObject.h"
#import "TGGenericShader.h"
#import "MeshBuffer.h"
#import "Camera.h"
#import "Texture.h"

@interface TGGeneric3dObject() {
    NSMutableArray * _buffers;
    NSMutableArray * _textures;
    const char * _initTextureName;
}
@end

@implementation TGGeneric3dObject

-(id)init
{
    return [self initWithFile:NULL];
}

-(id)initWithColor:(GLKVector4)color
{
    if( self = [self initWithFile:NULL] )
    {
        self.color = color;
    }
    
    return self;
}

-(id)initWithFile:(const char *)fileName
{
    if( (self = [super init]) )
    {
        _initTextureName = fileName;
        // Init steps (order dependent)
        
        [self createBuffer];
        [self createTexture];
        [self createShader];
        [self.shader use];
        [self getBufferLocations];
        [self getTextureLocations];
        
        self.opacity = 1.0;
        
        _initTextureName = NULL;
    }
    
    return self;
    
}

#pragma mark -
#pragma mark Initialization sequence
#pragma mark -


-(void)createBuffer
{
    NSLog(@"You should customize (void)createBuffer in your derivation");
    
    [self createBufferDataByType:@[@(sv_pos), @(sv_acolor)] numVertices:4 numIndices:6];
}

-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
{
    NSLog(@"You should customize (void)getBufferData: in your derivation");
    
    float * d = vertextData;
    //     x           y         z           r         g         b         a
    *d++ = -1; *d++ = -1; *d++ = 0;   *d++ = 1; *d++ = 0; *d++ = 0; *d++ = 1;
    *d++ = -1; *d++ =  1; *d++ = 0;   *d++ = 1; *d++ = 1; *d++ = 0; *d++ = 1;
    *d++ =  1; *d++ =  1; *d++ = 0;   *d++ = 1; *d++ = 0; *d++ = 1; *d++ = 1;
    *d++ =  1; *d++ = -1; *d++ = 0;   *d++ = 1; *d++ = 1; *d++ = 1; *d++ = 1;
    
    unsigned int * p = indexData;
    
    *p++ = 0; *p++ = 1; *p++ = 3; *p++ = 3; *p++ = 1; *p++ = 2;
}


-(void)createBufferDataByType:(NSArray *)svar
                  numVertices:(unsigned int)numVerticies
                   numIndices:(unsigned int)numIndices
{
    TGGenericElementParams params;

    memset(&params, 0, sizeof(params));
    
    params.numStrides = [svar count];

    params.strides = malloc(sizeof(TGVertexStride)*params.numStrides);
    
    for( int i = 0; i < params.numStrides; i++ )
    {
        TGVertexStride * stride = params.strides + i;
        SVariables type = [svar[i] intValue];
        switch (type) {
            case sv_normal:
            case sv_pos:
                StrideInit3f(stride, type);
                break;
            case sv_acolor:
                StrideInit4f(stride, sv_acolor);
                break;
            case sv_uv:
                StrideInit2f(stride, sv_uv);
                break;
#if DEBUG
            default:
                NSLog(@"Unknown SVariable");
                exit(1);
                break;
#endif
        }
    }
    
    params.numVertices = numVerticies;
    params.numIndices  = numIndices;
    GLsizei sz = [MeshBuffer calcDataSize:params.strides countStrides:params.numStrides numVertices:params.numVertices];
    params.vertexData = malloc(sz);
    if( params.numIndices > 0 )
        params.indexData = malloc( sizeof(unsigned int) * params.numIndices );
    
    [self getBufferData:params.vertexData indexData:params.indexData];

    MeshBuffer * buffer = [[MeshBuffer alloc] init];

    [buffer setData:params.vertexData
            strides:params.strides
       countStrides:params.numStrides
        numVertices:params.numVertices];
    
    if( params.indexData )
    {
        [buffer setIndexData:params.indexData
                  numIndices:params.numIndices];
    }
    
    if( !_buffers )
        _buffers = [NSMutableArray new];
    [_buffers addObject:buffer];
    
    free(params.strides);
    free(params.vertexData);
    if( params.indexData )
        free(params.indexData);
}

-(void)createTexture
{
    if( _initTextureName )
        [self addTexture:_initTextureName];
}

-(void)addTexture:(const char *)fileName
{
    NSString * ns = @(fileName);
    Texture * t = [[Texture alloc] initWithFileName:ns];
    if( !_textures )
        _textures = [NSMutableArray new];
    [_textures addObject:t];
}


-(Shader *)createShader
{
    NSMutableArray * arr = [NSMutableArray new];
    for( MeshBuffer * buffer in _buffers )
    {
        // this is bug waiting to happen?
        // wrt the same svType showing up in multiple
        // buffers
        [arr addObjectsFromArray:buffer.svTypes];
    }
    
    Shader * shader;
    
    self.shader = shader = [[TGGenericShader alloc] initWithSVaribles:arr];
    
    return shader;
}

-(void)configureLighting
{
    self.color = GLKVector4Make(1, 1, 1, 1);
    self.opacity = 1.0;
}

-(void)getBufferLocations
{
    for( MeshBuffer * buffer in _buffers )
    {
        [buffer getLocations:self.shader];
    }
}

-(void)getTextureLocations
{
    Shader * shader = self.shader;
    for(Texture * texture in _textures )
    {
        texture.uLocation = [shader location:sv_sampler];
    }
}

#pragma mark -
#pragma mark Uniform properties
#pragma mark -

-(void)setColor:(GLKVector4)color
{
    ((TGGenericShader *)self.shader).color = color;
    _color = color;
}

-(void)setOpacity:(float)opacity
{
    ((TGGenericShader *)self.shader).opacity = opacity;
    _opacity = opacity;
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
    TGGenericShader * genShader = (TGGenericShader *)self.shader;

    [genShader use];

    genShader.pvm = [self calcPVM];

    int target = 0;
    for( Texture * t in _textures )
    {
        [t bind:genShader target:target];
        ++target;
    }
    
    for( MeshBuffer * b in _buffers )
    {
        [b bind:genShader];
        [b draw];
    }    
}

-(void)drawBufferToShader:(Shader *)shader atLocation:(GLint)location
{
    for( MeshBuffer * buffer in _buffers )
    {
        if( [buffer assignMeshToShader:shader atLocation:location] )
        {
            [buffer draw];
            break; // we assume there is only one 'position' buffer. 
        }
    }
    
}
@end
