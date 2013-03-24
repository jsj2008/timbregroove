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

typedef enum TweenOps
{
    kTweenOpApplyTarget,
    kTweenOpApplyTargetToInitial,
    kTweenOpApplyDelta,
    kTweenOpGetBlock,
    kTweenOpReverse
} TweenOps;

typedef id (^TweenBlock)(TweenOps,float);

typedef union _TweenData {
    struct {
        float current;
        float initial;
        float target;
    }f;
    struct {
        int current;
        int initial;
        int target;
    }i;
    struct {
        CGPoint current;
        CGPoint initial;
        CGPoint target;
    }pt;
} TweenData;

#define _ops(a,b) [self ops:a f:b]

//--------------------------------------------------------------------------------
@interface TriggerTween () {
@public
    NSTimeInterval _runningTime;
    NSTimeInterval _duration;
    bool           _tweening;
    TweenFunction  _func;
    bool           _done;
    id             _paramBlock;
    TweenCallback  _callBack;
    char           _type;
    TweenData      _d;
    
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
        _type       = type;
        _parameter  = parameter;
        _paramBlock = [parameter getParamBlockOfType:type];
        _func       = func;
        _duration   = len;
        _queue      = queue;
    }
    return self;
}

-(id)ops:(TweenOps) op  f:(float)delta
{
    if( _type == _C_FLT )
    {
        switch (op) {
            case kTweenOpApplyTarget:
            {
                ((FloatParamBlock)_paramBlock)(_d.f.target);
                break;
            }
            case kTweenOpApplyTargetToInitial:
            {
                _d.f.initial = _d.f.target;
                break;
            }
            case kTweenOpReverse:
            {
                float tmp = _d.f.initial;
                _d.f.initial = _d.f.target;
                _d.f.target = tmp;
                break;
            }
            case kTweenOpApplyDelta:
            {
                float newValue = _d.f.initial + ((_d.f.target - _d.f.initial) * delta);
                ((FloatParamBlock)_paramBlock)(newValue);
                break;
            }
            case kTweenOpGetBlock:
            {
                return ^(float f) {
                    [self reset];
                    _d.f.initial = _d.f.current;
                    if( _parameter.additive )
                        _d.f.target = f + _d.f.initial;
                    else
                        _d.f.target = f;
                };
            }
        }
    }
    else if( _type == _C_INT )
    {
        switch (op) {
            case kTweenOpApplyTarget:
            {
                ((IntParamBlock)_paramBlock)(_d.i.target);
                break;
            }
            case kTweenOpApplyTargetToInitial:
            {
                _d.i.initial = _d.i.target;
                break;
            }
            case kTweenOpReverse:
            {
                int tmp = _d.i.initial;
                _d.i.initial = _d.i.target;
                _d.i.target = tmp;
                break;
            }
            case kTweenOpApplyDelta:
            {
                float newValue = (float)_d.i.initial + ((_d.i.target - _d.i.initial) * delta);
                ((FloatParamBlock)_paramBlock)((int) roundf(newValue));
                break;
            }
            case kTweenOpGetBlock:
            {
                return ^(int i) {
                    [self reset];
                    _d.i.initial = _d.i.current;
                    if( _parameter.additive )
                        _d.i.target = i + _d.i.initial;
                    else
                        _d.i.target = i;
                };
            }
        }
    }
    else if( _type == TGC_POINT )
    {
        switch (op) {
            case kTweenOpApplyTarget:
            {
                ((PointParamBlock)_paramBlock)(_d.pt.target);
                break;
            }
            case kTweenOpApplyTargetToInitial:
            {
                _d.pt.initial = _d.pt.target;
                break;
            }
            case kTweenOpReverse:
            {
                CGPoint tmp = _d.pt.initial;
                _d.pt.initial = _d.pt.target;
                _d.pt.target = tmp;
                break;
            }
            case kTweenOpApplyDelta:
            {
                CGPoint newValue;
                newValue.x = _d.pt.initial.x + ((_d.pt.target.x - _d.pt.initial.x) * delta);
                newValue.y = _d.pt.initial.y + ((_d.pt.target.y - _d.pt.initial.y) * delta);
                ((PointParamBlock)_paramBlock)(newValue);
                break;
            }
            case kTweenOpGetBlock:
            {
                return ^(CGPoint pt) {
                    [self reset];
                    _d.pt.initial = _d.pt.current;
                    if( _parameter.additive )
                        _d.pt.target = (CGPoint){ pt.x + _d.pt.initial.x, pt.y + _d.pt.initial.y };
                    else
                        _d.pt.target = pt;
                };
            }
        }
    }
    
    return nil;
}

-(void)dealloc
{
    TGLog(LLObjLifetime, @"%@ released",self);
}

-(void)decommission
{
    _paramBlock = nil;
    _callBack = nil;
    _parameter = nil;
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
    _tweening = true;
    [_parameter getValue:&_d ofType:_type];
    [_queue queue:self];
    _runningTime = 0.0;
    _done = false;
}

-(void)reverse
{
    _ops(kTweenOpReverse,0);
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


TweenCallback TweenReverseLooper = ^TweenDoneIndicator(TriggerTween *tt) {
    [tt reverse];
    return false;
};

//--------------------------------------------------------------------------------


@interface TriggerMap () {
    // NSString name : NSArray[] Parameter
    NSMutableDictionary * _parameters;
    
    // NSString name : NSArray[] names (from above)
    NSMutableDictionary * _mappings;
    
    NSMutableSet * _tweenerReleasePool;
    
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
    
    // it's even worse for these
    if( _tweenerReleasePool )
        [_tweenerReleasePool each:^(TriggerTween * tweener) {
            [tweener decommission];
        }];
    TGLog(LLObjLifetime, @"%@ released",self);
}

-(void)addParameters:(NSDictionary *)nameKeyParamValues
{
    [_parameters addEntriesFromDictionary:nameKeyParamValues];
}

-(void)addMappings:(NSDictionary *)triggerKeyParamNameValues
{
    [triggerKeyParamNameValues each:^(NSString *triggerName, NSString * paramName) {
        if( !_mappings[triggerName] )
            _mappings[triggerName] = [NSMutableArray new];
        [_mappings[triggerName] addObject:paramName];
    }];
}

-(void)removeMappings:(NSDictionary *)triggerKeyParamNameValues
{
    [triggerKeyParamNameValues apply:^(id triggerName, id paramName)
    {
        NSArray * stillValid = [(NSArray *)_mappings[triggerName] reject:^BOOL(id obj) {
            return [paramName isEqualToString:obj];
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
    ^id (id _annontated)
    {
        NSString * name = _annontated;
        
        // name[:tweenfunc:duration]
        
        NSArray * pieces = [name componentsSeparatedByString:@":"];
        if( [pieces count] > 1 )
        {
            name = pieces[0];
            Parameter * param = _parameters[name];
            if( !param )
                return nil;
            TweenFunction func = tweenFuncForString([((NSString *)pieces[1]) UTF8String]);
            float duration = [((NSString *)pieces[2]) floatValue];
            TriggerTween * tt = [TriggerTween withParameter:param func:func len:duration queue:_delegate type:type];
            tt->_callBack = callback;
            if( callback || param.forceDecommision )
            {
                if( !_tweenerReleasePool )
                    _tweenerReleasePool = [NSMutableSet new];
                [_tweenerReleasePool addObject:tt];
            }
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

    if( !arrayOfBlocks )
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
