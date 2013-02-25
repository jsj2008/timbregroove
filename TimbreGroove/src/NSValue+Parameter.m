//
//  NSValue+Parameter.m
//  TimbreGroove
//
//  Created by victor on 2/24/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//


#import "Parameter.h"

@implementation NSValue (Parameter)

+(id)valueWithParameter:(ParamValue)pvalue
{
    return [NSValue valueWithBytes:&pvalue objCType:@encode(ParamValue)];
}

-(ParamValue)parameterValue;
{
    ParamValue v;
    [self getValue:&v];
    return v;
}

-(GLKVector3)vector3Value;
{
    ParamValue v;
    [self getValue:&v];
    return *(GLKVector3 *)&v;
}

-(GLKVector4)vector4Value;
{
    ParamValue v;
    [self getValue:&v];
    return *(GLKVector4 *)&v;
}


@end
