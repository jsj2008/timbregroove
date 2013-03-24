//
//  DistortedGeneric.m
//  
//
//  Created by victor on 2/6/13.
//
//

#import "DistortedGeneric.h"


@interface DistortedGeneric ()
@end

@implementation DistortedGeneric

-(void)getShaderFeatures:(NSMutableArray *)features
{
    [super getShaderFeatures:features];
    [features addObject:kShaderFeatureDistort];
}

@end
