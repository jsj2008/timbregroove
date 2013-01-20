//
//  SimpleImage.m
//  TimbreGroove
//
//  Created by victor on 12/20/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "SimpleImage.h"
#import "GridPlane.h"

@implementation SimpleImage

-(void)createBuffer
{
    GridPlane * gp = [GridPlane gridWithIndicesIntoNames:@[@(gv_pos),@(gv_uv)]
                                                andDoUVs:true
                                            andDoNormals:false];
    [self addBuffer:gp];
}

@end
