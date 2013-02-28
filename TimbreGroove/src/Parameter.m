//
//  Parameter.m
//  TimbreGroove
//
//  Created by victor on 2/24/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Parameter.h"
#import "NSValue+Parameter.h"

/// for queueing
#import "Global.h"
#import "Scene.h"

typedef void (^NotifyBlock)(NSValue *);

@interface Parameter () {

    bool _tweening;
    
    bool _swellFlipped;
    
    NSTimeInterval _duration;
    TweenFunction  _function;
    NSTimeInterval _runningTime;
    ParamValue     _initValue;
    ParamValue     _targetValue;    
}

@end

@implementation Parameter

-(id)initWithDef:(ParameterDefintion *)def valueNotify:(id)notify
{
    self = [super init];
    if( self )
    {
        if( def )
        {
            [self setDefinition:def];
            [self calcScale];
        }
        _valueNotify = notify;
    }
    return self;
}

-(id)myParamBlock
{
    if( _myParamBlock )
        return _myParamBlock;
    
    __block Parameter * me = self;
    return ^(NSValue * nsvpayload){
        [me setValueTo:[nsvpayload ParamPayloadValue]];
    };
}
-(void)setDefinition:(ParameterDefintion *)definition
{
    _pd = definition;
    if( !_pd )
        return;
    
    switch (_pd->type)
    {
        case TG_COLOR:
            _numFloats = 4;
            break;
        case TG_VECTOR3:
            _numFloats = 3;
            break;
        case TG_POINT:
            _numFloats = 2;
            break;
        case TG_FLOAT:
            _numFloats = 1;
            break;
        case TG_BOOL_FLOAT:
        default:
            _numFloats = 0;
            break;
    }
}

-(void)calcScale
{
    if( _pd->type == TG_INT )
    {
        if( _pd->flags & kParamFlagPerformScaling )
            _pd->scale.f = 1.0 / (float)(_pd->max.i - _pd->min.i);
        
    }
    else for( int i = 0; i < _numFloats; i++ )
    {
        if( _pd->flags & kParamFlagPerformScaling )
            _pd->scale.fv[i] = (_pd->max.fv[i] - _pd->min.fv[i]);
        else
            _pd->scale.fv[i] = 1.0;
    }
}

-(ParameterDefintion *)definition
{
    return _pd;
}

-(void)setValueTo:(ParamPayload)inValue
{
    ParamValue   newValue;
    /*
        Here we need to determine a new value regarless of the
        what the incoming type is aot the param type.
     
     */
    float f;
    
    switch (inValue.type)
    {
        case TG_FLOAT:
        {
            switch (_pd->type)
            {
                case TG_FLOAT:
                    newValue.f = inValue.v.f;
                    break;
                    
                case TG_INT:
                    newValue.i = (int)roundf(inValue.v.f);
                    break;
                case TG_BOOL:
                    newValue.boool = inValue.v.f > 0.0 ? true : false;
                    break;
                default:
                    newValue.r =
                    newValue.g =
                    newValue.b =
                    newValue.a = inValue.v.f;
            };
            
        }
            break;
            
        case TG_BOOL:
        {
            switch (_pd->type)
            {
                case TG_BOOL:
                    newValue.boool = inValue.v.boool;
                    break;
                default:
                    f = inValue.v.boool ? 1.0 : 0.0;
                    newValue.r =
                    newValue.g =
                    newValue.b =
                    newValue.a = f;
            };
        }
        break;

        case TG_BOOL_FLOAT:
        {
            f = inValue.v.f > 0 ? 1.0 : 0.0;
            newValue.r =
            newValue.g =
            newValue.b =
            newValue.a = f;
        }
        break;
        
        case TG_INT:
        {
            switch (_pd->type) {
                case TG_INT:
                    newValue.i = inValue.v.i;
                    break;
                case TG_BOOL:
                    newValue.boool = !!inValue.v.i;
                    break;                    
                default:
                    f = inValue.v.i;
                    newValue.r =
                    newValue.g =
                    newValue.b =
                    newValue.a = f;
                    break;
            }
        }
        case TG_POINT:
        {
            switch (_pd->type)
            {
                case TG_BOOL:
                    // lookie all the policy-meister goo righ here!
                    newValue.boool = inValue.v.y > 0.0 ? true : false;
                    break;
                default:
                    newValue.x = inValue.v.x;
                    newValue.y = inValue.v.y;
                    newValue.z = _pd->currentValue.z;
                    newValue.a = _pd->currentValue.a;
            };
            
        }
        default:
            newValue = inValue.v;
            break;
    }

    if( _numFloats )
    {
        for( int i = 0; i < _numFloats; i++ )
        {
            if( _pd->flags & kParamFlagPerformScaling )
            {
                newValue.fv[i] *= _pd->scale.fv[i];
            }
            if( _pd->flags & kParamFlagsAdditiveValues || inValue.additive )
                newValue.fv[i] += _pd->currentValue.fv[i];
            if( newValue.fv[i] < _pd->min.fv[i] )
                newValue.fv[i] = _pd->min.fv[i];
            else if( newValue.fv[i] > _pd->max.fv[i] )
                newValue.fv[i] = _pd->max.fv[i];
        }
    }
    else if( _pd->type == TG_INT )
    {
        if( _pd->flags & kParamFlagPerformScaling )
        {
            newValue.i = (int)roundf( (float)newValue.i* _pd->scale.f);
            newValue.i += _pd->min.i;
        }
        if( _pd->flags & kParamFlagsAdditiveValues || inValue.additive )
            newValue.i += _pd->currentValue.i;
        if( newValue.i < _pd->min.i )
            newValue.i = _pd->min.i;
        else if( newValue.i > _pd->max.i )
            newValue.i = _pd->max.i;
    }
    
    if( inValue.duration != 0 )
    {
        _duration = inValue.duration;
        _function = inValue.function;
    }
    else if( _pd->duration != 0 )
    {
        _duration = _pd->duration;
        _function = _pd->function;
        
    }
    if( _duration == 0.0 )
    {
        _pd->currentValue = newValue;
        ((void (^)(NSValue *))_valueNotify)([NSValue valueWithParameter:_pd->currentValue]);
    }
    else
    {
        if( _tweening )
        {
            _pd->currentValue = _targetValue;
            ((void (^)(NSValue *))_valueNotify)([NSValue valueWithParameter:_pd->currentValue]);
        }
        
        _initValue = _pd->currentValue;
        _runningTime = 0.0;
        _targetValue = newValue;
        _isCompleted = false;
        _swellFlipped = false;
        if( !_tweening )
        {
            [self queue];
            _tweening = true;
        }
    }
    
}

-(void)killTween
{
    if( _tweening )
    {
		_runningTime = _duration;
		_isCompleted = true;
        _tweening = false;
        _targetValue = _pd->currentValue;
    }
}

- (void) update:(NSTimeInterval)dt
{
    _runningTime += dt;

	if (_runningTime >= _duration )
    {
		_runningTime = _duration;
		_isCompleted = true;
        _tweening = false;
	}
	
    ParamValue newValue;
    if( _isCompleted )
    {
        newValue = _targetValue;
    }
    else
    {
        float delta = [self tweenFunc:_function progression:_runningTime / _duration];
        switch (_pd->type)
        {
            case TG_INT:
                newValue.i = (int)( roundf( (float)_initValue.i + (_targetValue.i - _initValue.i) * delta) );
                break;
            case TG_COLOR:
                newValue.a = _initValue.a + (_targetValue.a - _initValue.a) * delta;
                // fall thru!
            case TG_VECTOR3:
                newValue.z = _initValue.z + (_targetValue.z - _initValue.z) * delta;
                // fall thru!
            case TG_POINT:
                newValue.y = _initValue.y + (_targetValue.y - _initValue.y) * delta;
                // fall thru!
            default:
                newValue.f = _initValue.f + (_targetValue.f - _initValue.f) * delta;
                break;
        }
        
    }
    
    _pd->currentValue = newValue;
    ((void (^)(NSValue *))_valueNotify)([NSValue valueWithParameter:_pd->currentValue]);    
}


/**
 * Calculate the tween function from progression [0..1]
 */
- (float) tweenFunc:(TweenFunction)func progression:(float)progression {
	
    switch (func) {
        case kTweenLinear:
            break;
            
        case kTweenEaseInSine:
            return 1.0 - cos(progression * M_PI / 2.0);
            
        case kTweenEaseOutSine:
            return sin(progression * M_PI / 2.0);
            
        case kTweenEaseInOutSine:
            return 0.5 * (1.0 + sin(1.5 * M_PI + progression * M_PI));
            
        case kTweenEaseOutBounce:
            return [self easeOutBounce:progression];
            
        case kTweenEaseInBounce:
            return 1.0 - [self easeOutBounce:1.0 - progression];
            
        case kTweenEaseOutThrow:
            return [self easeOutThrow:progression];
            
        case kTweenEaseInThrow:
            return 1.0 - [self easeOutThrow:1.0 - progression];
            
        case kTweenSwellInOut:
            return [self swellInOut:progression];
	}
	return progression;
}

- (float) swellInOut:(float)progresion {
    if( progresion < 0.5 )
        return [self tweenFunc:kTweenEaseInSine progression:progresion*2.0];
    if( !_swellFlipped )
    {
        ParamValue tmp = _initValue;
        _initValue = _targetValue;
        _targetValue = tmp;
        _swellFlipped = true;
    }
    return [self tweenFunc:kTweenEaseInSine progression:progresion];
    
}
- (float) easeOutBounce:(float)progression {
	// calculted with rebound speed = f * incoming speed
	float f = 0.7;
	float t1 = 1.0 / (2.0*f*f*f + 2.0*f*f + 2.0*f + 1.0);
	float t2 = t1 * (1.0 + 2 * f);
	float t3 = t1 * (1.0 + 2*f + 2*f*f);
    
	float g = 2.0 / (t1*t1);
	
	float v1 = g * t1;
	float v2 = f * v1;
	float v3 = f * v2;
	float v4 = f * v3;
	
	if (progression < t1) {
		return 0.5 * g * progression * progression;
		
	} else if (progression < t2) {
		float dt = progression - t1;
		return 1.0 - (v2 * dt - 0.5 * g * dt * dt);
		
	} else if (progression < t3) {
		float dt = progression - t2;
		return 1.0 - (v3 * dt - 0.5 * g * dt * dt);
		
	} else {
		float dt = progression - t3;
		return 1.0 - (v4 * dt - 0.5 * g * dt * dt);
	}
}

- (float) easeOutThrow:(float)progression {
	float f = 0.2;
	float g = 2 * (1.0 + 2 * f + 2 * sqrt(f * (1 + f)));
	float v0 = sqrt(2 * g * (1 + f));
	
	return v0 * progression - 0.5 * g * progression * progression;
}

-(void)queue
{
    [[Global sharedInstance].scene queue:self];
}

@end
