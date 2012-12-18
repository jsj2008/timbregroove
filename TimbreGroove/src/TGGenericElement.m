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

@implementation TGGenericElement

-(TGGenericElement *)initWithParams:(TGGenericElementParams *)params
{
    if( (self = [super init]))
    {
        TGGenericShader * shader = [[TGGenericShader alloc] initWithParams:params];

        self.shader = shader;
        
        TGVertexBuffer * buffer = [[TGVertexBuffer alloc] init];
        
        [buffer setData:params->bufferData
                strides:params->strides
           countStrides:params->numStrides
                numElem:params->numElements
                 shader:shader];
        
        [self addBuffer:buffer];
        
        if( params->texture )
           [self addTexture:params->texture];
        
    }
    
    return self;
}

-(void)addTexture:(const char *)fileName
{
    TGTexture * t = [[TGTexture alloc] initWithFileName:@(fileName)];
    TGGenericShader * shader = (TGGenericShader *)self.shader;
    GLint samplerLoc = [shader location:sv_sampler];
    if( !_textures )
        _textures = [NSMutableDictionary new];
    _textures[@(samplerLoc)] = t;
}

-(void)update:(NSTimeInterval)dt
{
    // update model and camera matrix here
    // so children can adjust accordingly
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    GLKMatrix4 pvm;
    pvm = [self calcPVM];
    
    TGGenericShader * genShader = (TGGenericShader *)self.shader;
    
    [genShader use];

    [genShader writeUniforms:pvm.m];
    
    for( TGVertexBuffer * b in _buffers )
    {
        [b setBuffer:genShader];
        [self attachTextures:0];
        [b draw];
    }    
}

@end
