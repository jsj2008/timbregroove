//
//  Light.h
//  TimbreGroove
//
//  Created by victor on 1/21/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Texture.h"

@interface Light : Material

@property (nonatomic) GLKVector3 direction; // is this lookAt ??
@property (nonatomic) GLKVector3 dirColor; // ??
@property (nonatomic) GLKVector3 pos; // haha, now we're just being random

@end
