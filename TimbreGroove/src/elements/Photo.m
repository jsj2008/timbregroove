//
//  Photo.m
//  TimbreGroove
//
//  Created by victor on 12/21/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Photo.h"

@implementation Photo

-(id) init
{
    Photo * p = [super initWithTextureFile:"Alex.png"];
    
    return p;
}

#if DEBUG
-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    [super render:w h:h];
}
#endif
@end
