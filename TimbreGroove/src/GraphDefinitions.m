//
//  GraphDefinitions.m
//  TimbreGroove
//
//  Created by victor on 2/5/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "GraphDefinitions.h"

@implementation GraphDefinitions

+(NSDictionary *)getDefinitionForName:(NSString *)name
{
	NSString * menuPath = [[NSBundle mainBundle] pathForResource:@"menus"
                                                          ofType:@"plist" ];
    
    NSDictionary * items = [[NSDictionary dictionaryWithContentsOfFile:menuPath] objectForKey:@"new_element"];
    
    return items[name][@"userData"];
}

+(NSArray *)getAllDefinitions:(NSMutableDictionary *)results
{
	NSString * menuPath = [[NSBundle mainBundle] pathForResource:@"menus"
                                                          ofType:@"plist" ];
    
    if( !results )
        results = [NSMutableDictionary new];
    
    [results addEntriesFromDictionary:[[NSDictionary dictionaryWithContentsOfFile:menuPath]
                                       objectForKey:@"new_element"]];
    
    return [results
             keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2)
             {
                 return [(NSNumber *)obj1[@"order"] compare:obj2[@"order"]];
             }];
}

@end
