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

@interface GenericBase () {
@protected
    bool _enableMultipleTextures;
    bool _useColor;
}

@end

@implementation GenericBase
-(void)createBuffer
{
    NSLog(@"You should customize (void)createBuffer in your derivation");
    
    [self createBufferDataByType:@[@(sv_pos), @(sv_acolor)] numVertices:4 numIndices:6];
}

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
    [self createShader];
    [self getBufferLocations];
    [self getTextureLocations];
    [self configureLighting];
    return self;
}

#pragma mark -
#pragma mark Initialization sequence
#pragma mark -

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


-(MeshBuffer *)createBufferDataByType:(NSArray *)svar
                  numVertices:(unsigned int)numVerticies
                   numIndices:(unsigned int)numIndices
{
    return [self createBufferDataByType:svar numVertices:numVerticies numIndices:numIndices uniforms:nil];
}

-(MeshBuffer *)createBufferDataByType:(NSArray *)svar
                  numVertices:(unsigned int)numVerticies
                   numIndices:(unsigned int)numIndices
                     uniforms:(NSDictionary*)uniformNames

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
            case sv_pos2f:
                StrideInit2f(stride, sv_pos); // hmmm
                break;
            case sv_customAttr2f:
            case sv_uv:
                StrideInit2f(stride, type);
                break;
            case sv_normal:
                self.lighting = true;
                // fall thru
            case sv_customAttr3f:
            case sv_pos:
                StrideInit3f(stride, type);
                break;
            case sv_customAttr4f:
            case sv_acolor:
                StrideInit4f(stride, type);
                break;
#if DEBUG
            default:
                NSLog(@"Unknown SVariable");
                exit(1);
                break;
#endif
        }
        if( uniformNames )
        {
            NSString * name = uniformNames[@(type)];
            if( name )
                stride->shaderAttrName = [name UTF8String];
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
    
    return buffer;
}

-(void)createTexture
{
}

-(void)createTextures
{
}


-(void)createShader
{
    self.shader = [ShaderPool getShader:@"generic" klass:[GenericShader class] header:[self getShaderHeader]];
}

- (NSString *)getShaderHeader
{
    NSMutableArray * arr = [NSMutableArray new];
    for( MeshBuffer * buffer in _buffers )
    {
        // this is bug waiting to happen?
        // wrt the same svType showing up in multiple
        // buffers
        [arr addObjectsFromArray:buffer.svTypes];
    }
    NSString * pre = @"";
    
    for( NSNumber * num in arr )
    {
        SVariables svar = [num intValue];
        NSString * ns;
        switch (svar) {
            case sv_acolor:
                ns = @"#define COLOR\n";
                break;
            case sv_normal:
                ns = @"#define NORMAL\n";
                break;
            case sv_uv:
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
    for( MeshBuffer * buffer in _buffers )
    {
        [buffer getLocations:self.shader];
    }
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
    GenericShader * genShader = (GenericShader *)self.shader;
    
    [genShader use];
    
    GLKMatrix4 pvm = [self calcPVM];
    genShader.pvm = pvm;
    
    if( _lighting )
    {
        genShader.normalMat = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(pvm), NULL);
        genShader.lightDir  = _lightDir;
        genShader.dirColor  = _dirColor;
        genShader.ambient   = _ambient;
    }
    
    if( _useColor )
        genShader.color = _color;

    [self bindTextures:genShader bind:true];
    
    for( MeshBuffer * b in _buffers )
    {
        [b bind:genShader];
        [b draw];
    }
    
    [self bindTextures:genShader bind:false];
}

-(void)bindTextures:(GenericShader *)genShader bind:(bool)bind
{
}

// capture hack
-(void)renderToCapture:(Shader *)shader atLocation:(GLint)location
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

@interface Generic() {
    Texture * _texture;
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
        _texture.uLocation = [shader location:sv_sampler];
    }
}

-(void)bindTextures:(GenericShader *)genShader bind:(bool)bind
{
    if( _texture )
    {
        if( bind )
            [_texture bind:genShader target:0];
        else
            [_texture unbind];
    }
    
}

-(void)setTextureFileName:(id)textureFileName
{
    _textureFileName = textureFileName;
    self.texture = [[Texture alloc] initWithFileName:_textureFileName];
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

-(void)bindTextures:(GenericShader *)genShader bind:(bool)bind
{
    int target = 0;
    for( Texture * t in _textures )
    {
        if( bind )
        {
            [t bind:genShader target:target];
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
