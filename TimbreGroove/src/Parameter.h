//
//  Parameter.h
//  TimbreGroove
//
//  Created by victor on 2/24/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"
#import "Tween.h"

@interface Parameter : NSObject {
@protected
    id _block;
}
+(id)withBlock:(id)block;
-(id)initWithBlock:(id)block;
-(id)getParamBlockOfType:(char)paramType;
-(void)getValue:(void *)p ofType:(char)type;
@end


typedef struct _FloatRange {
    float min;
    float max;
} FloatRange;

@interface FloatParameter : Parameter
+(id)withRange:(FloatRange)frange
         value:(float)value
         block:(id)block;

-(id)initWithRange:(FloatRange)frange
             value:(float)value
             block:(id)block;
@end


