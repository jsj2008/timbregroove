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

/*
 Used by tweener:
 true  - incoming tweener values will be added to current value
 false - incoming tweener values are passed to block "as is"
 */
@property (nonatomic) bool additive;

// only need this for non-float possibly animated parameters
-(void)setNativeValue:(void *)p ofType:(char)type size:(size_t)size;

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
 
 Additive:
  yes - incoming values are added the last value seen before. The sum
        is what shows up at your block
  no  - incoming values are passed to block "as is"
  default: YES - settable with .additive property
 
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
@protected
    float _value;
}

/*
 Use this for floats that require scaling.

 scaling: yes, clamping: yes
 */
+(id)withRange:(FloatRange)frange
         value:(float)value // N.B. native 'value'
         block:(id)block;

/*
 A float that is between 0-1
 
 scaling no, clamping: yes.
 */
+(id)with01Value:(float)value // range 0-1
         block:(id)block;

/*
 A straight up float. 
 
 scaling: no, clamping: no
 */
+(id)withValue:(float)value
         block:(id)block;

-(id)initWithValue:(float)value
             block:(id)block;

-(id)initWith01Value:(float)value
             block:(id)block;

-(id)initWithRange:(FloatRange)frange
             value:(float)value
             block:(id)block;

@end


