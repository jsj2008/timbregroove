//
//  GraphDefinitions.h
//  TimbreGroove
//
//  Created by victor on 2/5/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GraphDefinitions : NSObject

+(NSDictionary *)getDefinitionForName:(NSString *)name;
+(NSArray *)getAllDefinitions:(NSMutableDictionary *)results;

@end
