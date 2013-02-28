//
//  TriggerMap.m
//  TimbreGroove
//
//  Created by victor on 2/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "TriggerMap.h"
#import "Parameter.h"
#import <UIKit/UIGeometry.h>


@interface TriggerMap () {
    NSMutableDictionary * _paramNames;
    NSMutableDictionary * _mappings;
    
    __weak id _targetObj;
}
@end
@implementation TriggerMap

- (id)initWithWatchee:(id)objectToWatch
{
    self = [super init];
    if (self) {
        _targetObj = objectToWatch;
        _paramNames = [NSMutableDictionary new];
        _mappings = [NSMutableDictionary new];
        NSLog(@"created trigger map %@ (for %@)", self.description, ((NSObject *)_targetObj).description);
    }
    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if( [change[NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeSetting )
        for( void (^pblock)(NSValue *) in _paramNames[keyPath] )
        {
            NSValue * v = change[NSKeyValueChangeNewKey];
            ParamPayload pl = [v ParamPayloadValue];
            pblock([NSValue valueWithPayload:pl]);
        }
}

-(void)addParameters:(NSDictionary *)paramKeyBlockValues
{
    [self utilityMerge:paramKeyBlockValues dst:_paramNames watchProp:true];
}

-(void)addMappings:(NSDictionary *)triggerKeyParamValues
{
    [self utilityMerge:triggerKeyParamValues dst:_mappings watchProp:false];
}

-(void)trigger:(NSString const *)key withValue:(NSValue *)value;
{
    for (NSString * paramName in _mappings[key]) {
        [_targetObj setValue:value forKey:paramName];
    }
}

-(bool)expectsTrigger:(NSString const *)triggerName
{
    return _mappings[triggerName] != nil;
}

-(void)utilityMerge:(NSDictionary *)src
                dst:(NSMutableDictionary *)dst
          watchProp:(bool)watchProp
{
    for (NSString * srcKey in src) {
        if( !dst[srcKey] )
        {
            if(watchProp)
            {
                [_targetObj addObserver:self
                             forKeyPath:srcKey
                                options:NSKeyValueObservingOptionNew
                                context:NULL];
            }
            dst[srcKey] = [NSMutableArray new];
        }
        [dst[srcKey] addObject:src[srcKey]];
    }
}

-(void)detach:(id)objectNoLongerWatchWorthy
{
    for( NSString * name in _paramNames )
        [objectNoLongerWatchWorthy removeObserver:self forKeyPath:name];
}
@end
