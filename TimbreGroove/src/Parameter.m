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

@interface Parameter () {

    bool _tweening;
    
    NSTimeInterval _runningTime;
    ParamValue     _initValue;
    ParamValue     _targetValue;    
}

@end

@implementation Parameter

-(id)initWithDef:(ParameterDefintion *)def
{
    self = [super init];
    if( self )
    {
        if( def )
        {
            [self setDefinition:def];
            [self calcScale];
        }
    }
    return self;
}


-(void)setDefinition:(ParameterDefintion *)definition
{
    _pd = definition;
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
    for( int i = 0; i < _numFloats; i++ )
    {
        if( _pd->flags & kParamFlagPerformScaling )
            _pd->scale.fv[i] = 1.0 / (_pd->max.fv[i] - _pd->min.fv[i]);
        else
            _pd->scale.fv[i] = 1.0;
    }
}

-(ParameterDefintion *)definition
{
    return _pd;
}

-(void)setValueTo:(NSValue *)nsv
{
    ParamValue newValue;
    CGPoint * ppt;
    GLKVector3 * pv3;
    switch (_pd->type)
    {
        case TG_COLOR:
            newValue = [nsv parameterValue];
            break;
        case TG_VECTOR3:
            pv3 = (GLKVector3 *)&newValue;
            *pv3 = [nsv vector3Value];
            break;
        case TG_POINT:
            ppt = (CGPoint *)&newValue;
            *ppt = [nsv CGPointValue];
            break;
        case TG_FLOAT:
            if( [nsv isKindOfClass:[NSNumber class]])
                newValue.f = [((NSNumber *)nsv) floatValue];
            else
                newValue = [nsv parameterValue];
        case TG_BOOL_FLOAT:
            if( [nsv isKindOfClass:[NSNumber class]])
                newValue.f = [((NSNumber *)nsv) floatValue];
            else
                newValue = [nsv parameterValue];
            if( newValue.f > 0 )
                newValue.f = 1.0;
            else
                newValue.f = 0;
        default:
            break;
    }

    if( _numFloats )
    {
        for( int i = 0; i < _numFloats; i++ )
        {
            if( _pd->flags & kParamFlagPerformScaling )
            {
                newValue.fv[i] *= _pd->scale.fv[i];
                newValue.fv[i] += _pd->min.fv[i];
            }
            if( _pd->flags & kParamFlagsAdditiveValues )
                newValue.fv[i] += _pd->currentValue.fv[i];
            if( newValue.fv[i] < _pd->min.fv[i] )
                newValue.fv[i] = _pd->min.fv[i];
            else if( newValue.fv[i] > _pd->max.fv[i] )
                newValue.fv[i] = _pd->max.fv[i];
        }
    }
    
    if( _pd->duration == 0.0 )
    {
        _pd->currentValue = newValue;
    }
    else
    {
        _initValue = _pd->currentValue;
        _runningTime = 0.0;
        _targetValue = newValue;
        _isCompleted = false;
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
		_runningTime = _pd->duration;
		_isCompleted = true;
        _tweening = false;
        _targetValue = _pd->currentValue;
    }
}

- (void) update:(NSTimeInterval)dt
{
    _runningTime += dt;

	if (_runningTime >= _pd->duration )
    {
		_runningTime = _pd->duration;
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
        float delta = [self tweenFunc:_runningTime / _pd->duration];
        NSValue * nsv = nil;
        switch (_pd->type)
        {
            case TG_COLOR:
                newValue.a = _initValue.a + (_targetValue.a - _initValue.a) * delta;
                // fall thru!
            case TG_VECTOR3:
                newValue.z = _initValue.z + (_targetValue.z - _initValue.z) * delta;
                nsv = [NSValue valueWithParameter:newValue];
                // fall thru!
            case TG_POINT:
                newValue.y = _initValue.y + (_targetValue.y - _initValue.y) * delta;
                if( !nsv )
                    nsv = [NSValue valueWithCGPoint:*(CGPoint *)&newValue];
                // fall thru!
            default:
                newValue.f = _initValue.f + (_targetValue.f - _initValue.f) * delta;
                if( !nsv )
                    nsv = [NSNumber numberWithFloat:newValue.f];
                break;
        }
        
    }
    
    _pd->currentValue = newValue;
    
}

- (void) onComplete
{	
    if( _onCompleteBlock )
        _onCompleteBlock();
}

/**
 * Calculate the tween function from progression [0..1]
 */
- (float) tweenFunc:(float)progression {
	
    switch (_pd->function) {
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
	}
	return progression;
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
    [[Global sharedInstance].scene  queue:self];
}

@end
