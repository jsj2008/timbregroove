//
//  TriggerMap.m
//  TimbreGroove
//
//  Created by victor on 2/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#define SKIP_TRIGGER_DECLS
#import "TriggerMap.h"
#import "Parameter.h"
#import "Block.h"
#import "Tween.h"

//--------------------------------------------------------------------------------
@interface NSArray (reducer)

@end

@implementation NSArray (reducer)

- (NSArray *)reduce:(BKTransformBlock)block {
	NSParameterAssert(block != nil);
	
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
	
	[self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		id value = block(obj);
		if (value)
            [result addObject:value];
	}];
	
	return result;
}

@end

//--------------------------------------------------------------------------------

typedef enum TweenOps
{
    kTweenOpApplyTarget,
    kTweenOpApplyDelta,
    kTweenOpGetBlock,
} TweenOps;

typedef id (^TweenBlock)(TweenOps,float);

static int sizeForType(char type)
{
    static int __twSizes[] = { _C_FLT, sizeof(float), _C_INT, sizeof(int), TGC_POINT, sizeof(CGPoint) };
    for( int i = 0; i < (sizeof(__twSizes)/2*sizeof(int)); i += 2 )
        if( type == __twSizes[i] )
            return __twSizes[i+1];
    return -1;
}



//--------------------------------------------------------------------------------
@interface TriggerTween () {
@public
    NSTimeInterval _runningTime;
    NSTimeInterval _duration;
    bool           _tweening;
    TweenFunction  _func;
    bool           _done;
    id             _block;
    id             _paramBlock;
    TweenCallback  _callBack;
    TweenBlock     _ops;
    char           _type;
    float          _buf[12];
    void *         _current;
    void *         _initial;
    void *         _target;
    int            _size;
    
    Parameter * _parameter;
    __weak id<TriggerMapProtocol> _queue;
}
@end
@implementation TriggerTween

+(id)withParameter:(Parameter *)parameter
                  func:(TweenFunction)func
                   len:(NSTimeInterval)len
                 queue:(id<TriggerMapProtocol>)queue
                  type:(char)type
{
    return [[TriggerTween alloc] initWithParameter:parameter
                                              func:func
                                               len:len
                                              type:type
                                             queue:queue];
}

-(id)initWithParameter:(Parameter *)parameter
                  func:(TweenFunction)func
                   len:(NSTimeInterval)len
                  type:(char)type
                 queue:(id<TriggerMapProtocol>)queue
{
    self = [super init];
    if( self )
    {
        _type = type;
        _current = _buf;
        _initial = &_buf[4];
        _target  = &_buf[8];
        _size = sizeForType(type);
        _parameter = parameter;
        _paramBlock = [parameter getParamBlockOfType:type];
        _func = func;
        _duration = len;
        _queue = queue;
        
        TweenBlock FloatTweenBlock = ^id(TweenOps op, float delta)
        {
            if( op == kTweenOpApplyTarget )
            {
                ((FloatParamBlock)_paramBlock)(*(float *)_target);
            }
            else if( op == kTweenOpApplyDelta )
            {
                float initial = *(float *)_initial;
                float newValue = initial + ((*(float *)_target - initial) * delta);
                ((FloatParamBlock)_paramBlock)(newValue);
            }
            else if( op == kTweenOpGetBlock )
            {
                return ^(float f) {
                    [self reset];
                    if( _parameter.additive )
                        *(float *)_target = f + *(float *)_initial;
                    else
                        *(float *)_target = f;
                };
            }
            return nil;
        };
        
        TweenBlock IntTweenBlock = ^id(TweenOps op, float delta)
        {
            if( op == kTweenOpApplyTarget )
            {
                ((IntParamBlock)_paramBlock)(*(int *)_target);
            }
            else if( op == kTweenOpApplyDelta )
            {
                float initial = *(int *)_initial;
                float newValue = initial + ((*(int *)_target - initial) * delta);
                ((IntParamBlock)_paramBlock)((int)roundf(newValue));
            }
            else if( op == kTweenOpGetBlock )
            {
                return ^(float f) {
                    [self reset];
                    if( _parameter.additive )
                        *(float *)_target = f + *(float *)_initial;
                    else
                        *(float *)_target = f;
                };
            }
            return nil;
        };
        
        TweenBlock PointTweenBlock = ^id(TweenOps op, float delta )
        {
            if( op == kTweenOpApplyTarget )
            {
                ((PointParamBlock)_paramBlock)(*(CGPoint *)_target);
            }
            else if( op == kTweenOpApplyDelta )
            {
                CGPoint initial = *(CGPoint *)_initial;
                CGPoint target = *(CGPoint *)_target;
                CGPoint newValue;
                newValue.x = initial.x + ((target.x - initial.x) * delta);
                newValue.y = initial.y + ((target.y - initial.y) * delta);
                ((PointParamBlock)_paramBlock)(newValue);
            }
            else if( op == kTweenOpGetBlock )
            {
                return ^(CGPoint pt) {
                    [self reset];
                    if( _parameter.additive )
                    {
                        CGPoint initial = *(CGPoint *)_initial;
                        pt.x += initial.x;
                        pt.y += initial.y;
                    }
                    *(CGPoint *)_target = pt;
                };
            }
            return nil;
        };
        
        if( type == _C_FLT )
            _ops = FloatTweenBlock;
        else if( type == _C_INT )
            _ops = IntTweenBlock;
        else if( type == TGC_POINT )
            _ops = PointTweenBlock;
        
    }
    return self;
}

-(id) block
{
    return _ops(kTweenOpGetBlock,0);
}

-(BOOL)update:(NSTimeInterval)dt
{
    _runningTime += dt;
    
	if (_runningTime >= _duration )
    {
		_done = true;
        _ops(kTweenOpApplyTarget,0);
		_runningTime = _duration;
        _tweening = false;
        if( _callBack )
            _done = _callBack(self);
	}
    else
    {
        float delta = tweenFunc(_func, _runningTime / _duration);
        _ops(kTweenOpApplyDelta,delta);
    }
 
    return _done;
}

-(void)reset
{
    bool additive = _parameter.additive;
    [_parameter getValue:_current ofType:_type];
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
            _ops(kTweenOpApplyTarget,0);
            memcpy(_initial, _target, _size);
        }
        else
        {
            memcpy(_initial, _current, _size);
        }
    }
    else
    {
        _tweening = true;
        memcpy(_initial, _current, _size);
    }
    [_queue queue:self];
    _runningTime = 0.0;
    _done = false;
}

-(void)reverse
{
    float tmp[4];
    memcpy(tmp, _initial, _size);
    memcpy(_initial, _target, _size);
    memcpy(_target, tmp, _size);
    _runningTime = 0.0;
    _done = false;
    _tweening = true;
}

-(bool)isDone
{
    return _done;
}
@end

//--------------------------------------------------------------------------------




//--------------------------------------------------------------------------------


TweenCallback TweenLooper = ^TweenDoneIndicator(TriggerTween *tt) {
    [tt reverse];
    return false;
};

//--------------------------------------------------------------------------------


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

-(void)dealloc
{
    // got to do this to eliminate circular references
    // to objects returning blocks that point to
    // themselves with self.* and ivars.
    // This seems to do the trick:
    [_parameters each:^(id key, Parameter * obj) {
        [obj releaseBlock];
    }];
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

-(id)getTrigger:(NSString const *)triggerName ofType:(char)type cb:(id)callback
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
            TriggerTween * tt = [TriggerTween withParameter:param func:func len:duration queue:_delegate type:type];
            tt->_callBack = callback;
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

    NSArray * arrayOfBlocks = [paramNames reduce:blockForParamName];

    if( [arrayOfBlocks count] == 0 )
        return nil; // hey, YOU MISSPELLED THE PARAM NAME IN config.plist
    
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
    return [self getTrigger:triggerName ofType:_C_FLT cb:nil];
}

-(PointParamBlock)getPointTrigger:(NSString const *)triggerName
{
    return [self getTrigger:triggerName ofType:TGC_POINT cb:nil];
}

-(PointerParamBlock)getPointerTrigger:(NSString const *)triggerName
{
    return [self getTrigger:triggerName ofType:_C_PTR  cb:nil];
}

-(IntParamBlock)getIntTrigger:(const NSString *)triggerName
{
    return [self getTrigger:triggerName ofType:_C_INT cb:nil];
}

-(FloatParamBlock)getFloatTrigger:(NSString const *)triggerName cb:(TweenCallback)cb
{
    return [self getTrigger:triggerName ofType:_C_FLT cb:cb];
}

-(PointParamBlock)getPointTrigger:(NSString const *)triggerName cb:(TweenCallback)cb
{
    return [self getTrigger:triggerName ofType:TGC_POINT cb:cb];
}

-(IntParamBlock)getIntTrigger:(NSString const *)triggerName cb:(TweenCallback)cb
{
    return [self getTrigger:triggerName ofType:_C_INT cb:cb];
}

-(PointerParamBlock)getPointerTrigger:(NSString const *)triggerName cb:(TweenCallback)cb
{
    return [self getTrigger:triggerName ofType:_C_PTR  cb:cb];
}

@end
