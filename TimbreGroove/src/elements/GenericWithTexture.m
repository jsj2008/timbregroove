//
//  SimpleImage.m
//  TimbreGroove
//
//  Created by victor on 12/20/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "GenericWithTexture.h"
#import "GridPlane.h"
#import "Texture.h"

@implementation GenericWithTexture

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
    GridPlane * gp = [GridPlane gridWithIndicesIntoNames:@[@(gv_pos),@(gv_uv)]
                                                andDoUVs:true
                                            andDoNormals:false];
    [self addBuffer:gp];
}

-(float)gridWidth
{
    GridPlane * gp = (GridPlane *)_buffers[0];
    return gp.width;
}

@end
