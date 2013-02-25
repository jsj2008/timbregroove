//
//  Parameter.h
//  TimbreGroove
//
//  Created by victor on 2/24/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"

typedef void (^TweenCompleteBlock)();
typedef void (^ParamBlock)(NSValue *);


typedef enum TweenFunction {    
    kTweenLinear,
    kTweenEaseInSine,
    kTweenEaseOutSine,
    kTweenEaseInOutSine,
    kTweenEaseInBounce,
    kTweenEaseOutBounce,
    kTweenEaseInThrow,
    kTweenEaseOutThrow
} TweenFunction;

typedef enum ParamFlags {
    kParamFlagNone = 0,
    kParamFlagPerformScaling = 1,
    kParamFlagsAdditiveValues = 1 << 1,
} ParamFlags;

union _ParamValue {
    float fv[4];
    float f;
    struct { float x, y,  z;  };
    struct { float r,  g,  b,  a;  };
};

typedef union _ParamValue ParamValue;

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

-(id)initWithDef:(ParameterDefintion *)def;

@property (nonatomic,strong) TweenCompleteBlock   onCompleteBlock;
@property (nonatomic)        ParameterDefintion * definition;
@property (nonatomic,strong) NSString const *     parameterName;
@property (nonatomic)        bool                 isCompleted;

-(void)setValueTo:(NSValue *)nsv;


@property (nonatomic) NSTimeInterval tweenStart;

-(void)update:(NSTimeInterval)dt;

// for derived classes
-(void)queue;

@end

#import "NSValue+Parameter.h"
