//
//  MenuItem.m
//  TimbreGroove
//
//  Created by victor on 12/15/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "MenuItem.h"

@implementation MenuItem

-(id)initWithIcon:(NSString *)fileName;
{
    if( (self = [super initWithFileName:[fileName UTF8String]]) ) {
        
    }
    
    return self;
}

-(void)handleSelect
{
    
}

@end
