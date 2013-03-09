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
@property (nonatomic) bool additive;

// only need this for non-float possibly animated parameters
-(void)setNativeValue:(void *)p ofType:(char)type size:(size_t)size;

@end


typedef struct _FloatRange {
    float min;
    float max;
} FloatRange;

@interface FloatParameter : Parameter {
@protected
    float _value;
}

+(id)withRange:(FloatRange)frange
         value:(float)value // N.B. 'value' will be scaled
         block:(id)block;

+(id)withValue:(float)value
         block:(id)block;

-(id)initWithValue:(float)value
             block:(id)block;

-(id)initWithRange:(FloatRange)frange
             value:(float)value
             block:(id)block;

@end


