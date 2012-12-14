//
//  Texture.m
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Texture.h"
#import "TGVertexBuffer.h"
#import "TGVariables.h"
#import "TGTexture.h"

@implementation Texture


-(Texture *)initWithImage:(NSString *)textureName
                  andData:(void *)data
              numElements:(unsigned int)numElements
{
    if( (self = [super initWithName:@"texture"]) )
    {
        _buffer = [TGVertexBuffer new];
        
        TGVertexStride s[2];
        StrideInit3fv(s,    "a_position");
        StrideInit2fUV(s+1, "a_textureUV");
        
        [_buffer setData:data strides:s countStrides:2 numElem:numElements shader:self];
        
        TGTexture * t = [[TGTexture alloc] initWithFileName:textureName];
        [self addSampler:@"u_sampler" texture:t];
    }
    
    return self;
}

@end
