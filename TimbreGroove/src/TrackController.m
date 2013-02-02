//
//  TGViewController.m
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TrackController.h"
#import "View.h"

@implementation TrackController

-(void)startGL
{
    [self setupGL];
    View * tv = (View*)self.view;
    
    [tv createNode:@{@"instanceClass":@"PoolScreen"}];
}


@end
