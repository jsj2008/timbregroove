//
//  NSArray+Reducer.h
//  TimbreGroove
//
//  Created by victor on 3/22/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (reducer)
- (NSMutableArray *)reduce:(BKTransformBlock)block;
@end

@interface NSDictionary (reducer)
- (NSDictionary *)mapReduce:(BKKeyValueTransformBlock)block;
- (NSMutableArray *)keyReduce:(BKKeyValueTransformBlock)block;
@end