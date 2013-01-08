//
//  TGGenericElement.m
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGGenericElement.h"
#import "TGGenericShader.h"
#import "TGVertexBuffer.h"
#import "TGCamera.h"
#import "TGTexture.h"

@interface TGGenericElement() {
    NSMutableArray * _buffers;
    NSMutableArray * _textures;
}
@end

@implementation TGGenericElement

-(id)init
{
    if( (self = [super init]) )
    {
        // Init steps (order dependent)
        
        [self createBuffer];
        [self createTexture];
        self.shader = [self createShader];
        [self registerBufferWithShader];
        [self registerTextureWithShader];
    }
    
    return self;
}

#pragma mark -
#pragma mark Initialization sequence
#pragma mark -


-(void)createBuffer
{
    NSLog(@"You should customize (void)createBuffer in your derivation");
    
    SVariables types = { SV_pos, sv_acolor, SV_NONE };
    [self createBufferDataByType:types numVertices:4 numIndices:6];
}

-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
{
    NSLog(@"You should customize (void)getBufferData: in your derivation");
    
    float * d = vertextData;
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

    params.numStrides = [svar count];

    params->strides = malloc(sizeof(TGVertexStride)*params.numStrides);
    
    for( int i = 0; i < params.numStrides; i++ )
    {
        TGVertexStride * stride = params->strides + i;
        SVariables type = svar[i];
        switch (type) {
            case sv_normal:
            case sv_pos:
                StrideInit3f(stride+i, type);
                break;
            case sv_acolor:
                StrideInit4f(stride+i, sv_acolor);
                break;
            case sv_uv:
                StrideInit2f(stride+i, sv_uv);
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
    GLsizei sz = [TGVertexBuffer calcDataSize:params.strides countStrides:params.numStrides numVertices:params.numVertices];
    params.vertexData = malloc(sz);
    if( params.numIndices > 0 )
        params.indexData = malloc( sizeof(unsigned int) * params.numIndices );
    
    [self getBufferData:params.vertexData indexData:params.indexData];

    TGVertexBuffer * buffer = [[TGVertexBuffer alloc] init];

    [buffer setData:params.vertexData
            strides:params.strides
       countStrides:params.numStrides
        numVertices:params.numVertices];
    
    if( params.indexData )
    {
        [buffer setIndexData:params.indexData
                  numIndices:params.numIndices];
    }
    
    [self addBuffer:buffer];
    
    free(params->strides);
    free(params->vertexData);
    if( params->indexData )
        free(params->indexData);
}

-(void)createTexture
{
}

-(void)addTexture:(const char *)fileName
{
    NSString * ns = @(fileName);
    TGTexture * t = [[TGTexture alloc] initWithFileName:ns];
    if( !_textures )
        _textures = [NSMutableArray new];
    [_textures addObject:t];
}


-(TGShader *)createShader
{
    NSMutableArray * arr = [NSMutableArray new];
    for( TGVertexBuffer * buffer in _buffers )
    {
        [arr addObjectsFromArray:buffer.svTypes];
    }
    
    self.shader = [[TGGenericShader alloc] initWithSVaribles:arr];
}

-(void)configureLighting
{
    self.color = GLKVector4Make(1, 1, 1, 1);
    self.opacity = 1.0;
}

-(void)registerBufferWithShader
{
    for( TGVertexBuffer * buffer in _buffers )
    {
        [buffer assignUniforms:self.shader];
    }
}

-(void)registerTextureWithShader
{
    TGShader * shader = self.shader;
    for(TGTexture * texture in _textures )
    {
        texture.glSampler = [shader location:sv_sampler];
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

    [genShader writePVM:[self calcPVM].m];

    int target = 0;
    for( TGTexture * t in _textures )
    {
        [t bindToShader:shader target:target];
        ++target;
    }
    
    for( TGVertexBuffer * b in _buffers )
    {
        [b bindBuffer:genShader];
        [b draw];
    }    
}

-(void)drawBufferToShader:(TGShader *)shader atLocation:(GLint)location
{
    for( TGVertexBuffer * buffer in _buffers )
    {
        if( [buffer assignMeshToShader:shader atLocation:location] )
        {
            [buffer draw];
            break; // hmmmmm
        }
    }
    
}
@end
