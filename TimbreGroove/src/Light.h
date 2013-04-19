//
//  Light.h
//  TimbreGroove
//
//  Created by victor on 1/21/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Generic.h"

@interface DirectionalLight : NSObject<ShaderFeature>

@property (nonatomic) GLKVector3 direction; 
@property (nonatomic) GLKVector3 position;

@end
