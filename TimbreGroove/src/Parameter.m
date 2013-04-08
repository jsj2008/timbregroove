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
    void * _nativeValue;
    char _nativeValueType;
    size_t _nativeValueSize;
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

-(void)releaseBlock
{
    _block = nil;
}

-(void)dealloc
{
    TGLog(LLObjLifetime, @"%@ released",self);
}

-(char)nativeType
{
    return _paramType;
}

-(void)getValue:(void *)p ofType:(char)type
{
    if( _nativeValue && (type == _nativeValueType) )
        memcpy(p, _nativeValue, _nativeValueSize);
}

-(void)setNativeValue:(void *)p ofType:(char)type size:(size_t)size
{
    _nativeValue = p;
    _nativeValueType = type;
    _nativeValueSize = size;
}

-(id)getParamBlockOfType:(char)requestParamType
{
    if( requestParamType == _paramType || _paramType == _C_VOID )
    {
        return _block;
    }
    
    if( requestParamType == _C_FLT )
    {
        if( _paramType == TGC_POINT )
        {
            return ^(float f) {
                ((PointParamBlock)_block)((CGPoint){f,f});
            };
        }
    }
    else if( requestParamType == TGC_POINT )
    {
        if( _paramType == TGC_VECTOR3 )
        {
            return ^(CGPoint pt) {
                return ((Vector3ParamBlock)_block)((TGVector3){pt.x,pt.y,0});
            };
        }
        
        if( _paramType == _C_FLT )
        {
            return ^(CGPoint pt) {
                float len = GLKVector2Length((GLKVector2){pt.x,pt.y});
                ((FloatParamBlock)_block)(len);
            };
        }
    }
    else if( requestParamType == TGC_VECTOR3 )
    {
        if( _paramType == TGC_POINT )
        {
            return ^(GLKVector3 vec3) {
                return ((PointParamBlock)_block)((CGPoint){vec3.x,vec3.y});
            };
        }
        
        if( _paramType == _C_FLT )
        {
            return ^(GLKVector3 vec3) {
                float len = GLKVector3Length(vec3);
                ((FloatParamBlock)_block)(len);
            };
        }
    }

    TGLog(LLShitsOnFire, @"Unsupported param trigger: %c requested on a %c type",requestParamType,_paramType);
    exit(-1);
    return nil;
}

@end

@interface FloatParameter () {
    FloatRange _range;
    float _scale;
    float _scaleShift;
}
@end

@implementation FloatParameter

+(id)withScaling:(FloatRange)frange
           value:(float)value
           block:(id)block
{
    return [[FloatParameter alloc] initWithScaling:frange value:value block:block scaleShift:0];
}


-(id)initWithScaling:(FloatRange)frange
             value:(float)value
             block:(id)block
{
    return [self initWithScaling:frange value:value block:block scaleShift:0];
}

+(id)withNeg11Scaling:(FloatRange)frange
                value:(float)value // N.B. native 'value'
                block:(id)block
{
    return [[FloatParameter alloc] initWithScaling:frange value:value block:block scaleShift:1];
}

-(id)initWithNeg11Scaling:(FloatRange)frange
                    value:(float)value // N.B. native 'value'
                    block:(id)block;
{
    return [self initWithScaling:frange value:value block:block scaleShift:1];
}

+(id)with01Value:(float)value
         block:(id)block;
{
    return [[FloatParameter alloc] initWith01Value:value block:block];
}

-(id)initWith01Value:(float)value
            block:(id)block
{
    self = [super initWithBlock:^(float f) {
        if( f < 0 )
            f = 0;
        else if( f > 1 )
            f = 1;
        _value = f;
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
        ((FloatParamBlock)block)(f);
    }];
    
    if( self )
    {
        _value = value;
        ((FloatParamBlock)_block)(value);
    }
    return self;
}


-(id)initWithScaling:(FloatRange)frange
             value:(float)value
             block:(id)block
        scaleShift:(float)scaleShift
{
    self = [super initWithBlock:^(float f) {
        _value = f;
        if( _scale )
            f = ((f + _scaleShift) * _scale) + _range.min;
        if( f < _range.min )
        {
            f = _range.min;
            _value = 0;
        }
        else if( f > _range.max )
        {
            f = _range.max;
            _value = 1.0;
        }
        ((FloatParamBlock)block)(f);
    }];
    
    if( self )
    {
        _scaleShift = scaleShift;
        _range = frange;
        _scale = frange.max - frange.min;
        if( scaleShift )
            _scale *= _scaleShift * 0.5;
        _value = value;
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
    else if( type == TGC_VECTOR3 )
    {
        *(GLKVector3 *)p = (GLKVector3){_value,_value,_value};
    }
}


@end

