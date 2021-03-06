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

/*
 A parameter that is exposed as being 'trigger-able'
 
 The parameters for the block are calculated dynamically. A trigger
 will request a block with a parameter type that is compatible. If 
 the native isn't what was requested then a "smart" choice is attempted
 and a wrapper block is returned.
 
 Often that will just fail and kill the app. So, you know,
 don't do try to hook incompatible triggers and parameters together.
 
 An instance of this can be used for tweening but only for compatible
 triggers. (Derive and override 'getValue:ofType:' if that's a problem)
 
 If you want to tween an instance of this class you must call 
 'setNativeValue:ofType:size' with a pointer that will keep the
 parameter's value up to date. 
 */
@interface Parameter : NSObject {
@protected
    id _block;
}
+(id)withBlock:(id)block;
-(id)initWithBlock:(id)block;
-(id)getParamBlockOfType:(char)paramType;
-(void)getValue:(void *)p ofType:(char)type;
-(void)releaseBlock;
/*
 Used by tweener:
 true  - incoming tweener values will be added to current value
 false - incoming tweener values are passed to block "as is"
 */
@property (nonatomic) bool additive;

// used by wrappers
@property (nonatomic,readonly) char nativeType;

// only need this for non-float possibly animated parameters
-(void)setNativeValue:(void *)p ofType:(char)type size:(size_t)size;

// for self-referential blocks
@property (nonatomic) bool forceDecommision;

// parameter only applies to object 
@property (nonatomic,strong) id targetObject;
@end


typedef struct _FloatRange {
    float min;
    float max;
} FloatRange;

/*
 
 N.B. All comments are prepended with the caution: IN THEORY...
 
 This exposes an tweenable float. 

 Things that might happen to incoming trigger/tween values before
 your block is called:
 
 Additive (only applies when tweening):
  yes - incoming values are added the last value seen before. The sum
        is what shows up at your block
  no  - incoming values are passed to block "as is"
  default: depends on which init: is used (settable with .additive property)
 
 Scaling: 
  yes - incoming values are expected to be 0:1 (sometimes -1:1) and
        are scaled to a native value within range
  no  - incoming values are passed to block "as is"
  default: depends on which init: is used
 
 Clamping:
  yes - incoming values are kept within range
  no  - incoming values ignore any range
  default: depends on which init: is used
 
 */
@interface FloatParameter : Parameter {
@public
    float _value;
}

/*
 Use this for floats that require scaling from 0:1.

 scaling: yes, clamping: yes additive: yes
 */
+(id)withScaling:(FloatRange)frange
         value:(float)value // N.B. native 'value'
         block:(id)block;

/*
 Use this for floats that require scaling from -1:1.
 
 scaling: yes, clamping: yes additive: yes
 */
+(id)withNeg11Scaling:(FloatRange)frange
         value:(float)value // N.B. native 'value'
         block:(id)block;


/*
 A float that is between 0-1
 
 scaling no, clamping: yes,  additive: no
 */
+(id)with01Value:(float)value // range 0-1
         block:(id)block;

/*
 A straight up float. 
 
 scaling: no, clamping: no,  additive: yes
 */
+(id)withValue:(float)value
         block:(id)block;


-(id)initWithScaling:(FloatRange)frange
             value:(float)value
             block:(id)block;

-(id)initWithNeg11Scaling:(FloatRange)frange
                    value:(float)value // N.B. native 'value'
                    block:(id)block;

-(id)initWithValue:(float)value
             block:(id)block;


-(id)initWith01Value:(float)value
             block:(id)block;

@end


