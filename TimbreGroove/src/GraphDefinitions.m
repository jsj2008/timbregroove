//
//  GraphDefinitions.m
//  TimbreGroove
//
//  Created by victor on 2/5/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "GraphDefinitions.h"
#import "Config.h"

@implementation GraphDefinitions

+(NSDictionary *)getDefinitionForName:(NSString *)name
{
    NSDictionary * items = [[Config sharedInstance] valueForKey:@"new_element"];
    
    return items[name][@"userData"];
}

+(NSArray *)getAllDefinitions:(NSMutableDictionary *)results
{
    if( !results )
        results = [NSMutableDictionary new];
    
    [results addEntriesFromDictionary:[[Config sharedInstance] valueForKey:@"new_element"]];
    
    return [results
             keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2)
             {
                 return [(NSNumber *)obj1[@"order"] compare:obj2[@"order"]];
             }];
}

@end
