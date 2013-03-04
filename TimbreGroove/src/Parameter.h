//
//  Parameter.h
//  TimbreGroove
//
//  Created by victor on 2/24/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"

//typedef void (^ParamBlock)(NSValue *);
#define ParamBlock id

typedef enum TweenFunction {    
    kTweenLinear,
    kTweenEaseInSine,
    kTweenEaseOutSine,
    kTweenEaseInOutSine,
    kTweenEaseInBounce,
    kTweenEaseOutBounce,
    kTweenEaseInThrow,
    kTweenEaseOutThrow,
    kTweenSwellInOut
} TweenFunction;

typedef enum ParamFlags {
    kParamFlagNone = 0,
    kParamFlagPerformScaling = 1,
    kParamFlagsAdditiveValues = 1 << 1,
} ParamFlags;

union _ParamValue {
    float fv[4];
    int i;
    float f;
    bool boool;
    struct { float x, y,  z;  };
    struct { float r,  g,  b,  a;  };
    AudioFrameCapture mu;
};

typedef union _ParamValue ParamValue;

#define PvToPoint(pv) *(CGPoint *)(&((pv).x))
#define PvToV3(pv)    *(GLKVector3 *)(&((pv).x))
#define PvToV4(pv)    *(GLKVector4 *)(&((pv).x))

typedef struct ParamPayload {
    ParamValue      v;
    TGParameterType type;
    bool            additive;
    NSTimeInterval  duration;
    TweenFunction   function;
} ParamPayload;


typedef struct ParameterDefintion {
    TGParameterType type;
    ParamValue      def;
    ParamValue      min;
    ParamValue      max;
    TweenFunction   function;
    NSTimeInterval  duration;
    ParamFlags      flags;
    
    // calculated at runtime...
    ParamValue      scale;
    ParamValue      currentValue; // native
    ParamValue      normalized;   // scaled
    
} ParameterDefintion;


@interface Parameter : NSObject {
    @protected
    ParameterDefintion * _pd;
    int _numFloats;
}

-(id)initWithDef:(ParameterDefintion *)def valueNotify:(id)notify;

@property (nonatomic,strong) id valueNotify;
@property (nonatomic,strong) id myParamBlock;

-(void)setValueTo:(ParamPayload)inValue;

// Tweening
-(void)update:(NSTimeInterval)dt;
@property (nonatomic) bool isCompleted;

// for derived classes
-(void)queue;
@property (nonatomic)        ParameterDefintion * definition;
@property (nonatomic,strong) NSString const *  parameterName;
-(void)calcScale;

@end

@interface PropertyParameter : Parameter {
@protected
    NSString * _propName;
}

-(id)initWithDef:(ParameterDefintion *)def
            name:(NSString const *)name
            prop:(NSString *)propName;
-(id)initWithDef:(ParameterDefintion *)def
            name:(NSString const *)name;
@property (nonatomic,strong) NSString * propName;
@end

@interface NonAnimatingPropertyParameter : PropertyParameter
-(id)initWithTarget:(id)target andName:(NSString *)name;
@end

#import "NSValue+Parameter.h"
