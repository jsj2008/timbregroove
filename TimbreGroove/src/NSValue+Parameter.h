//
//  NSValue+Parameter.h
//  TimbreGroove
//
//  Created by victor on 2/24/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSValue (Parameter)
+(id)valueWithParameter:(ParamValue)pvalue;
+(id)valueWithPayload:(ParamPayload)payload;

// this *Value nomenclature is how obj-c
// runtime unboxes (no shit)
-(ParamPayload)ParamPayloadValue;
-(ParamValue)ParamValueValue;
-(CGPoint)CGPointValue;
-(GLKVector3)GLKVector3Value;
-(GLKVector4)GLKVector4Value;
-(bool)boolValue;
-(float)floatValue;
-(int)intValue;
@end
