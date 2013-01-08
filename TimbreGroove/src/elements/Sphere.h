//
//  Sphere.h
//  TimbreGroove
//
//  Created by victor on 12/19/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Generic.h"

@class Texture;

@interface Sphere : Generic
-(id)initWithTexture:(Texture *)texture;
-(id)initWithRadius:(float)radius longs:(float)longs lats:(float)lats;
-(id)initWithRadius:(float)radius longs:(float)longs lats:(float)lats textureFile:(const char *)fileName;

@end
