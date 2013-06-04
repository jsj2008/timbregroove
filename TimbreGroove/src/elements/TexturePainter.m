//
//  SimpleImage.m
//  TimbreGroove
//
//  Created by victor on 12/20/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TexturePainter.h"
#import "GridPlane.h"
#import "Material.h"

@implementation TexturePainter {
    GridPlane * gp;
}

-(id)initWithText:(NSString *)text
{
    self = [super init];
    if( self )
    {
        self.texture = [[Texture alloc] initWithString:text];
    }
    return self;
}

-(id)initWithFileName:(NSString *)imageFileName
{
    self = [super init];
    if( self )
    {
        self.texture = [[Texture alloc] initWithFileName:imageFileName];
    }
    return self;
}

-(void)createBuffer
{
    gp = [GridPlane gridWithIndicesIntoNames:@[@(gv_pos),@(gv_uv)]];
    [self addBuffer:gp];
}

-(float)gridWidth
{
    return gp.width;
}

-(void)setTexture:(Texture *)texture
{
    if( _texture )
        [self removeShaderFeature:_texture];
    [self addShaderFeature:texture];
    _texture = texture;
}

@end
