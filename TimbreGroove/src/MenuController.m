//
//  TGMenuController.m
//  TimbreGroove
//
//  Created by victor on 2/1/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "MenuController.h"
#import "Text.h"

@implementation MenuController

-(void)startGL
{
    [EAGLContext setCurrentContext:self.context];
    View * tv = (View*)self.view; // [self makeTrackView:klass];
    
    Text * t = [tv createNode:@{@"instanceClass":@"Text"}];
    t.scale = (GLKVector3){ 13.0, 1, 1 };
}


@end
