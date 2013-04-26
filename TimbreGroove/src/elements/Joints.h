//
//  Bones.h
//  TimbreGroove
//
//  Created by victor on 4/22/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShaderFeature.h"

@interface Joints : NSObject<ShaderFeature>
+(id)withArmatureNodes:(NSArray *)nodes;
@property (nonatomic) bool dirty;
@end
