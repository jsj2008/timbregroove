//
//  TriggerMap.h
//  TimbreGroove
//
//  Created by victor on 2/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void (^ParamBlock)(NSValue *);

@interface TriggerMap : NSObject
-(id)initWithWatchee:(id)objectToWatch;
-(void)addParameters:(NSDictionary *)paramKeyBlockValues;
-(void)addMappings:(NSDictionary *)triggerKeyParamValues;
-(void)trigger:(NSString const *)key withValue:(NSValue *)value;

@end


