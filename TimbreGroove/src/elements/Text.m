//
//  Text.m
//  TimbreGroove
//
//  Created by victor on 12/21/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Text.h"
#import "Texture.h"

@implementation Text

-(void)createTexture
{
    Texture * t = [[Texture alloc] initWithString:@"Ass Over Teakettle"];
    if( !_textures )
        _textures = [NSMutableArray new];
    [_textures addObject:t];
}


@end
