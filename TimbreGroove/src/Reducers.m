//
//  NSArray+Reducer.m
//  TimbreGroove
//
//  Created by victor on 3/22/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Reducers.h"

//--------------------------------------------------------------------------------
@implementation NSArray (reducer)

- (NSMutableArray *)reduce:(BKTransformBlock)block {
	NSParameterAssert(block != nil);
	
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
	
	[self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		id value = block(obj);
		if (value)
            [result addObject:value];
	}];
	
    if( [result count] > 0 )
        return result;
    
    return nil;
}

@end

//--------------------------------------------------------------------------------
@implementation NSDictionary (reducer)

- (NSMutableDictionary *)mapReduce:(BKKeyValueTransformBlock)block {
	NSParameterAssert(block != nil);
	
	NSMutableDictionary *result = [NSMutableDictionary new];
    
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id value = block(key,obj);
        if( value )
            result[key] = value;
    }];
	
    if( [result count] > 0 )
        return result;
    
    return nil;
}

- (NSMutableArray *)keyReduce:(BKKeyValueTransformBlock)block {
	NSParameterAssert(block != nil);
	
	NSMutableArray *result = [NSMutableArray new];
    
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id newKey = block(key,obj);
        if( newKey )
           [result addObject:newKey];
    }];
	
    if( [result count] > 0 )
        return result;
    
    return nil;
}

@end
