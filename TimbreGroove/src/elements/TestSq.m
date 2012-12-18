//
//  TestSq.m
//  TimbreGroove
//
//  Created by victor on 12/17/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TestSq.h"
#import "TGCamera.h"

@implementation TestSq

-(id)init
{
    return [super initWithFileName:"squareTest.tif"];
}

-(void)update:(NSTimeInterval)dt
{
    TGCamera * camera = self.camera;
    GLKVector3 pos = camera.position;
    pos.z -= 1.0;
    if( pos.z > -0.1 )
        pos.z = -10;
    camera.z = pos.z;
}


@end
