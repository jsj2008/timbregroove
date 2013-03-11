//
//  TriggerMap.m
//  TimbreGroove
//
//  Created by victor on 2/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "TriggerMap.h"
#import "Parameter.h"
#import "Block.h"
#import "Tween.h"

@interface FloatTriggerTween : TriggerTween {
    float _initial;
    float _target;
}

-(id)initWithParameter:(Parameter *)parameter
                  func:(TweenFunction)func
                   len:(NSTimeInterval)len
                 queue:(id<TriggerMapProtocol>)queue;
@end

@interface PointTriggerTween : TriggerTween {
    CGPoint _initial;
    CGPoint _target;
}

-(id)initWithParameter:(Parameter *)parameter
                  func:(TweenFunction)func
                   len:(NSTimeInterval)len
                 queue:(id<TriggerMapProtocol>)queue;
@end


@interface TriggerTween () {
@public
    NSTimeInterval _runningTime;
    NSTimeInterval _duration;
    bool           _tweening;
    TweenFunction  _func;
    bool           _done;
    id             _block;
    id             _paramBlock;
    
    Parameter * _parameter;
    __weak id<TriggerMapProtocol> _queue;
}
@end
@implementation TriggerTween

+(id)ttWithParameter:(Parameter *)parameter
                  func:(TweenFunction)func
                   len:(NSTimeInterval)len
                 queue:(id<TriggerMapProtocol>)queue
                  type:(char)type
{
    if( type == _C_FLT )
    {
        return [[FloatTriggerTween alloc] initWithParameter:parameter
                                                       func:func
                                                        len:len
                                                      queue:queue];
    }
    if( type == TGC_POINT )
    {
        return [[PointTriggerTween alloc] initWithParameter:parameter
                                                       func:func
                                                        len:len
                                                      queue:queue];
    }
    
    NSLog(@"Unsupported trigger tween type: %c",type);
    exit(-1);
    return nil;
}

-(id)initWithParameter:(Parameter *)parameter
                  func:(TweenFunction)func
                   len:(NSTimeInterval)len
                  type:(char)type
{
    self = [super init];
    if( self )
    {
        _parameter = parameter;
        _paramBlock = [parameter getParamBlockOfType:type];
        _func = func;
        _duration = len;
    }
    return self;
}

-(void)dealloc
{
    NSLog(@"Tweener is gone");
}

-(id) block { return nil; }
-(void)applyTarget {}
-(void)applyDelta:(float)delta {}

-(BOOL)update:(NSTimeInterval)dt
{
    _runningTime += dt;
    
	if (_runningTime >= _duration )
    {
		_done = true;
        [self applyTarget];
		_runningTime = _duration;
        _tweening = false;
	}
    else
    {
        float delta = tweenFunc(_func, _runningTime / _duration);
        [self applyDelta:delta];
    }
 
    return _done;
}

-(bool)isDone
{
    return _done;
}
@end


@implementation FloatTriggerTween

-(id)initWithParameter:(Parameter *)parameter
                  func:(TweenFunction)func
                   len:(NSTimeInterval)len
                 queue:(id<TriggerMapProtocol>)queue
{
    
    self = [super initWithParameter:parameter
                               func:func
                                len:len
                               type:_C_FLT];
    
    if( self )
    {
        _queue = queue;
    }
    return self;
}

-(id)block
{
    return ^(float f) {
        bool additive = _parameter.additive;
        float current;
        [_parameter getValue:&current ofType:_C_FLT];
        if( _tweening )
        {
            /*
             This can happen when a new animation of this
             parameter starts before a previous one ends. In
             that case we simply jump to the current target
             value (hopefully not too harsh on the ears/eyes!)
             and roll on.
             */
            if( additive )
            {
                [self applyTarget];
                _initial = _target;
            }
            else
            {
                _initial = current;
            }
        }
        else
        {
            _tweening = true;
            _initial = current;
        }
        [_queue queue:self];
        _target = f;
        if( additive )
            _target += _initial;
        _runningTime = 0.0;
        _done = false;
    };

}
-(void)applyTarget
{
    ((FloatParamBlock)_paramBlock)(_target);
}

-(void)applyDelta:(float)delta
{
    float newValue = _initial + ((_target - _initial) * delta);
    ((FloatParamBlock)_paramBlock)(newValue);
}
@end

@implementation PointTriggerTween

-(id)initWithParameter:(Parameter *)parameter
                  func:(TweenFunction)func
                   len:(NSTimeInterval)len
                 queue:(id<TriggerMapProtocol>)queue
{
    
    self = [super initWithParameter:parameter
                               func:func
                                len:len
                               type:TGC_POINT];
    
    if( self )
    {
        _queue = queue;
    }
    return self;
}

-(id)block
{
    return ^(CGPoint pt) {
        _done = false;
        if( _tweening )
        {
            [self applyTarget];
            _initial = _target;
        }
        else
        {
            [_parameter getValue:&_initial ofType:TGC_POINT];
            _tweening = true;
        }
        [_queue queue:self];
        _target = pt;
        if( _parameter.additive )
            _target = (CGPoint){ _target.x + _initial.x, _target.y + _initial.y };
        _runningTime = 0.0;
    };
}

-(void)applyTarget
{
    ((PointParamBlock)_paramBlock)(_target);
}

-(void)applyDelta:(float)delta
{
    CGPoint newValue;
    newValue.x = _initial.x + ((_target.x - _initial.x) * delta);
    newValue.y = _initial.y + ((_target.y - _initial.y) * delta);
    ((PointParamBlock)_paramBlock)(newValue);
    
}
@end

@interface TriggerMap () {
    // NSString name : NSArray[] Parameter
    NSMutableDictionary * _parameters;
    
    // NSString name : NSArray[] names (from above)
    NSMutableDictionary * _mappings;
    
    NSMutableArray * _tweeners;
    
    __weak id<TriggerMapProtocol> _delegate;
}
@end
@implementation TriggerMap

-(id)initWithDelegate:(id<TriggerMapProtocol>)delegate
{
    self = [super init];
    if (self) {
        _parameters = [NSMutableDictionary new];
        _mappings = [NSMutableDictionary new];
        _delegate = delegate;
    }
    return self;
}

-(void)addParameters:(NSDictionary *)nameKeyParamValues
{
    [_parameters addEntriesFromDictionary:nameKeyParamValues];
}

-(void)addMappings:(NSDictionary *)triggerKeyParamNameValues
{
    for( NSString * triggerName in triggerKeyParamNameValues )
    {
        if( !_mappings[triggerName] )
            _mappings[triggerName] = [NSMutableArray new];
        [_mappings[triggerName] addObject:triggerKeyParamNameValues[triggerName]];
    }
}

-(void)removeMappings:(NSDictionary *)triggerKeyParamNameValues
{
    [triggerKeyParamNameValues apply:^(id triggerName, id triggerObj)
    {
        NSArray * stillValid = [(NSArray *)_mappings[triggerName] reject:^BOOL(id obj) {
            return [triggerObj isEqualToString:obj];
        }];
        
        if( stillValid && [stillValid count])
            _mappings[triggerName] = stillValid;
        else
            [_mappings removeObjectForKey:triggerName];
    }];
}

-(id)getTrigger:(NSString const *)triggerName ofType:(char)type
{
    BKTransformBlock blockForParamName =
    ^id (id _name)
    {
        NSString const * name = _name;
        // name:tweenfunc:duration
        NSArray * pieces = [name componentsSeparatedByString:@":"];
        if( [pieces count] > 1 )
        {
            NSString * name = pieces[0];
            Parameter * param = _parameters[name];
            if( !param )
                return nil;
            TweenFunction func = tweenFuncForString([((NSString *)pieces[1]) UTF8String]);
            float duration = [((NSString *)pieces[2]) floatValue];
            TriggerTween * tt = [TriggerTween ttWithParameter:param func:func len:duration queue:_delegate type:type];
//            [_tweeners addObject:tt];
            return [tt block];
        }
        
        Parameter * param = _parameters[name];
        if( !param )
            return nil;
        return [param getParamBlockOfType:type];
    };
    
    
    NSArray * paramNames = _mappings[triggerName];
    
    if( !paramNames ) // maybe it's not a trigger, but a param name?
        return blockForParamName(triggerName);

    NSArray * arrayOfBlocks = [paramNames map:blockForParamName];

    if( [arrayOfBlocks count] == 1 )
        return arrayOfBlocks[0];
    
    id retBlock;
    
    // N.B. the apply method will fire these off conconurrently
    if( type == _C_FLT )
    {
        retBlock =  ^(float f) {[arrayOfBlocks apply:^(FloatParamBlock blk) { blk(f);}];};
    }
    else if( type == _C_PTR )
    {
        retBlock =  ^(void *p) {[arrayOfBlocks apply:^(PointerParamBlock blk) { blk(p);}];};
    }
    else if( type == TGC_POINT )
    {
        retBlock =  ^(CGPoint pt) {[arrayOfBlocks apply:^(PointParamBlock blk) { blk(pt);}];};
    }
    else if( type == _C_INT )
    {
        retBlock =  ^(int i) {[arrayOfBlocks apply:^(IntParamBlock blk) { blk(i);}];};
    }
    
    return [retBlock copy];
    
}
-(FloatParamBlock)getFloatTrigger:(NSString const *)triggerName
{
    return [self getTrigger:triggerName ofType:_C_FLT];
}

-(PointParamBlock)getPointTrigger:(NSString const *)triggerName
{
    return [self getTrigger:triggerName ofType:TGC_POINT];
}

-(PointerParamBlock)getPointerTrigger:(NSString const *)triggerName
{
    return [self getTrigger:triggerName ofType:_C_PTR];
}

-(IntParamBlock)getIntTrigger:(const NSString *)triggerName
{
    return [self getTrigger:triggerName ofType:_C_INT];
}
@end
