//
//  Fluid.h
//  TimbreGroove
//
//  Created by victor on 1/2/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "TG3dObject.h"

@class FluidShader;

@interface Fluid : TG3dObject
@property (nonatomic) float px;
@property (nonatomic) float py;
@property (nonatomic) CGSize viewSize;
@property (nonatomic,strong) FluidShader * fshader;

-(void)setupWorldWithWidth:(unsigned int)width andHeight:(unsigned int)height;
@end
