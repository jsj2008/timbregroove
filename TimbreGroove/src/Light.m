//
//  Light.m
//  TimbreGroove
//
//  Created by victor on 1/21/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Light.h"

@implementation Light

-(id)init
{
    if( (self = [super init]) )
    {
        _direction = GLKVector3Make(0, 0.5, 0);
        _dirColor = GLKVector3Make(1, 1, 1);
        _pos = GLKVector3Make(0, 0, -1);
    }
    
    return self;
}
@end
