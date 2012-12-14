//
//  Texture.h
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGShader.h"

@class TGVertexBuffer;

@interface Texture : TGShader
@property (nonatomic,strong) TGVertexBuffer * buffer;

-(Texture *)initWithImage:(NSString *)textureName
                  andData:(void *)data
              numElements:(unsigned int)numElements;
@end
