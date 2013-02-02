//
//  TGViewController.m
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TrackController.h"

@implementation TrackController

-(void)startGL
{
    [self setupGL];
    View * tv = (View*)self.view; // [self makeTrackView:klass];
    
    [tv createNode:@{@"instanceClass":@"PoolScreen"}];
}


@end
