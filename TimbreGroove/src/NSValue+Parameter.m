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
    static const char * encodedName = @encode(ParamValue);
    
    return [NSValue valueWithBytes:&pvalue objCType:encodedName];
}

+(id)valueWithPayload:(ParamPayload)payload
{
    static const char * encodedName = @encode(ParamPayload);
    
    return [NSValue valueWithBytes:&payload objCType:encodedName];
}

-(ParamPayload)ParamPayloadValue { ParamPayload pp; [self getValue:&pp]; return pp; }
-(ParamValue)ParamValueValue     { ParamValue v; [self getValue:&v]; return v;}
-(CGPoint)CGPointValue           { ParamValue v; [self getValue:&v]; return PvToPoint(v); }
-(GLKVector3)GLKVector3Value     { ParamValue v; [self getValue:&v]; return PvToV3(v); }
-(GLKVector4)GLKVector4Value     { ParamValue v; [self getValue:&v]; return PvToV4(v); }
-(bool)boolValue                 { ParamValue v; [self getValue:&v]; return v.boool; }
-(float)floatValue               { ParamValue v; [self getValue:&v]; return v.f; }
-(int)intValue                   { ParamValue v; [self getValue:&v]; return v.i; }

@end