//
//  Text.m
//  TimbreGroove
//
//  Created by victor on 12/21/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Text.h"
#import "Texture.h"
#import "Camera.h"

@interface Text()
{
    NSTimeInterval _time;
}

@end
@implementation Text

-(void)createTexture
{
    self.texture = [[Texture alloc] initWithString:@"Ass Over Teakettle"];
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    [super render:w h:h];
}
-(void)update:(NSTimeInterval)dt
{
    _time += (dt*15);
    GLKVector3 rot = { 0, GLKMathDegreesToRadians(_time), 0 };
    self.rotation = rot;
}
@end
