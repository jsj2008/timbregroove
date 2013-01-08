//
//  AOTK.m
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "AOTK.h"
#import "TGViewController.h"

@implementation AOTK

-(AOTK *)init
{
    return [super initWithFileName:@"aotk-ass-bare-512.tif"];
}

-(void)update:(TGViewController *)vc
{
    [super update:vc];

    static NSTimeInterval dt;
    
    dt += (vc.timeSinceLastUpdate * 50.0f);
    
    GLfloat r = GLKMathDegreesToRadians(dt);
    
    GLKVector3 rot = { 0, r, 0 };
    self.rotation = rot;
}

@end
