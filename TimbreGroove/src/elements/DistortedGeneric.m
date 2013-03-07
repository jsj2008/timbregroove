//
//  DistortedGeneric.m
//  
//
//  Created by victor on 2/6/13.
//
//

#import "DistortedGeneric.h"
#import "GraphView+Touches.h"


@interface DistortedGeneric () {
    NSTimeInterval _dTimer;
}
@end

@implementation DistortedGeneric

-(void)setDistortionFactor:(float)distortionFactor
{
    [self.shader writeToLocation:gv_distortionFactor type:TG_FLOAT data:&distortionFactor];
    _distortionFactor = distortionFactor;
}

-(void)getShaderFeatures:(NSMutableArray *)putHere
{
    [super getShaderFeatures:putHere];
    [putHere addObject:kShaderFeatureDistort];
}


@end
