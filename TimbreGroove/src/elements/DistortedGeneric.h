//
//  DistortedGeneric.h
//  
//
//  Created by victor on 2/6/13.
//
//
#import "Generic.h"
#import "RecordGesture.h"

@interface DistortedGeneric : Generic<RecordGestureReceiver>
@property (nonatomic) float distortionFactor;
@end
