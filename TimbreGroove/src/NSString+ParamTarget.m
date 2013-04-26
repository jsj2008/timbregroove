//
//  NSString+ParamTarget.m
//  TimbreGroove
//
//  Created by victor on 4/24/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "NSString+ParamTarget.h"

@implementation NSString (ParamTarget)

-(NSString *)stringByAppendingParamTarget:(NSString *)targetName
{
    return [self stringByAppendingFormat:@"#%@",targetName];
}

@end
