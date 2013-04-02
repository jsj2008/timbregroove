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

@implementation GenericWithTexture {
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
    gp = [GridPlane gridWithIndicesIntoNames:@[@(gv_pos),@(gv_uv)]
                                                andDoUVs:true
                                            andDoNormals:false];
    [self addBuffer:gp];
}

-(float)gridWidth
{
    return gp.width;
}

@end
