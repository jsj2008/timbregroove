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
-(ParamValue)parameterValue;
-(GLKVector3)vector3Value;
-(GLKVector4)vector4Value;
@end
