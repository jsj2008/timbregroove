//
//  Photo.m
//  TimbreGroove
//
//  Created by victor on 12/21/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Photo.h"

@implementation Photo

-(id)wireUp
{
    if( !self.textureFileName )
        self.textureFileName = @"Alex.png";
    return [super wireUp];
}

#if DEBUG
-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    [super render:w h:h];
}
#endif
@end
