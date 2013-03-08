//
//  Parameter.m
//  TimbreGroove
//
//  Created by victor on 2/24/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Parameter.h"
#import "Block.h"

@interface Parameter () {
    char _paramType;
}

@end
@implementation Parameter

+(id)withBlock:(id)block
{
    return [[Parameter alloc] initWithBlock:block];
}

-(id)initWithBlock:(id)block
{
    self = [super init];
    if( self )
    {
        _block = block;
        _paramType = GetBlockArgumentType(block);
        _additive = true;
        
    }
    return self;
}

-(void)getValue:(void *)p ofType:(char)type
{
    
}

-(id)getParamBlockOfType:(char)paramType
{
    if( paramType == _C_FLT )
    {
        if( _paramType == _C_FLT )
            return _block;
        
        if( _paramType == TGC_POINT )
        {
            return ^(float f) {
                ((PointParamBlock)_block)((CGPoint){f,f});
            };
        }
    }
    else if( paramType == _C_INT )
    {
        if( paramType == _C_INT )
            return  _block;
    }
    else if( paramType == TGC_POINT )
    {
        if( _paramType == TGC_POINT )
            return _block;
        
        if( _paramType == _C_FLT )
        {
            return ^(CGPoint pt) {
                float len = GLKVector2Length((GLKVector2){pt.x,pt.y});
                ((FloatParamBlock)_block)(len);
            };
        }
    }
    else if( paramType == _C_PTR )
    {
        if( _paramType == _C_PTR )
            return _block;
    }
    NSLog(@"Unsupported param trigger: %c requested on a %c type",paramType,_paramType);
    exit(-1);
    return nil;
}

@end

@interface FloatParameter () {
    FloatRange _range;
    float _scale;
}
@end

@implementation FloatParameter

+(id)withValue:(float)value
         block:(id)block;
{
    return [[FloatParameter alloc] initWithValue:value block:block];
}

-(id)initWithValue:(float)value
            block:(id)block
{
    self = [super initWithBlock:^(float f) {
        _value = f;
        if( f < 0 )
            f = 0;
        else if( f > 1 )
            f = 1;
        ((FloatParamBlock)block)(f);
    }];
    
    if( self )
    {
        _value = value;
        self.additive = false;
        ((FloatParamBlock)_block)(value);
    }
    return self;
    
}

+(id)withRange:(FloatRange)frange
         value:(float)value
         block:(id)block
{
    return [[FloatParameter alloc] initWithRange:frange value:value block:block];
}

-(id)initWithRange:(FloatRange)frange
             value:(float)value
             block:(id)block
{
    self = [super initWithBlock:^(float f) {
        _value = f;
        if( _scale )
            f = (f * _scale) + _range.min;
        if( f < _range.min )
            f = _range.min;
        else if( f > _range.max )
            f = _range.max;
        ((FloatParamBlock)block)(f);
    }];
    
    if( self )
    {
        _value = value;
        _range = frange;
        _scale = frange.max - frange.min;
        ((FloatParamBlock)_block)(value); 
    }
    return self;
}

-(void)getValue:(void *)p ofType:(char)type
{
    if( type == _C_FLT )
    {
        *(float *)p = _value;
    }
    else if( type == TGC_POINT )
    {
        *(CGPoint *)p = (CGPoint){_value,_value};
    }
}


@end

