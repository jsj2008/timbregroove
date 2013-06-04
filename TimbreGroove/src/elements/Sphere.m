//
//  Sphere.m
//  TimbreGroove
//
//  Created by victor on 12/19/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Sphere.h"
#import "SphereOid.h"

@implementation Sphere

-(void)createBuffer
{
    SphereOid * sp = [SphereOid sphereWithdIndicesIntoNames:@[@(gv_pos),   @(gv_uv),  @(gv_normal)]];
    [self addBuffer:sp];
}
@end
