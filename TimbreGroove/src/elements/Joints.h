//
//  Bones.h
//  TimbreGroove
//
//  Created by victor on 4/22/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShaderFeature.h"

@class MeshSceneArmatureNode;

@interface Joints : NSObject<ShaderFeature>
+(id)withArmatureNodes:(NSArray *)nodes;
-(MeshSceneArmatureNode *)jointWithName:(NSString *)name;
@property (nonatomic) bool disabled;
@end
