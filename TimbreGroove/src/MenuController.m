//
//  TGMenuController.m
//  TimbreGroove
//
//  Created by victor on 2/1/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "MenuController.h"
#import "Text.h"

@interface MenuController () {
    Text * _text;
}

@end

@implementation MenuController

-(void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)startGL
{
    [self setupGL];
    Text * text = [self createNode:@{@"instanceClass":@"Text"}];
    text.scale = (GLKVector3){ 10.0, 1.0, 1.0 };
    
    //self.viewview.backColor = (GLKVector4){0.5,1.0,0.5,1.0};
}

@end
