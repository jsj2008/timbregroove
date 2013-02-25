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
    NSMutableDictionary * _parameters;
    NSMutableDictionary * _mappings;
    
    id _targetObj;
}
@end
@implementation TriggerMap

- (id)initWithWatchee:(id)objectToWatch
{
    self = [super init];
    if (self) {
        _targetObj = objectToWatch;
        _parameters = [NSMutableDictionary new];
        _mappings = [NSMutableDictionary new];
    }
    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if( [change[NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeSetting )
        for( ParamBlock pblock in _parameters[keyPath] )
        {
            NSValue * v = change[NSKeyValueChangeNewKey];
            pblock(v);
        }
}

-(void)addParameters:(NSDictionary *)paramKeyBlockValues
{
    [self utilityMerge:paramKeyBlockValues dst:_parameters setProp:true];
}

-(void)addMappings:(NSDictionary *)triggerKeyParamValues
{
    [self utilityMerge:triggerKeyParamValues dst:_mappings setProp:false];
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
            setProp:(bool)setProp
{
    for (NSString * srcKey in src) {
        if( !dst[srcKey] )
        {
            if(setProp)
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


@end
