//
//  TriggerMap.h
//  TimbreGroove
//
//  Created by victor on 2/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>


/*
 
 CONCEPTS and DEFINITIONS:
 --------------------------
 An object with tweakable (sp?) attributes is a 'target' or 'watchee'
 
 The tweakable attributes are each exposed as a 'Paramater'
 
 Each Parameter has two meta pieces of data: a name and an executable
 block that takes a single NSValue as a parameter.

 A event that arrives with a piece of data is called a 'Trigger'
 
 Each Trigger can be mapped to one or more Parameter.
 
 When a Trigger (with it's data) arrives here, each Parameter associated 
 with have its execution block invoked.
 
 USAGE:
 -------
 1. Initialize this class with the watchee.
 2. Add the Parameters (these must be properties on the watchee, or at least
    handled by watchee:valueForUndefinedKey and watchee:setValue:forUndefinedKey)
 3. Add the mapping between Trigger names and Parameter names
 4. Wait for triggers
 
 REAL WORLD USAGE:
 -----------------
 See the Scene class.
 
 IMPLEMENTATION
 ---------------
 This class will call :addObserver on the watchee for every Parameter. When a
 trigger happens, it will set the propery in the watchee. That will invoke
 this class's :observeValueForKeyPath which will call the Parameter's execution 
 block. 
 
*/

@interface TriggerMap : NSObject

-(id)initWithWatchee:(id)objectToWatch;

// @{ paramName1: paraBlock1, [paraName_n: paramBlock_n, ...]}
-(void)addParameters:(NSDictionary *)paramKeyBlockValues;

// @{ triggerName1: paramName1, [triggerName_n: paramName_n, ...]}
-(void)addMappings:(NSDictionary *)triggerKeyParamValues;

-(void)trigger:(NSString const *)key withValue:(NSValue *)value;

// optimization for modules that will only send trigger if
// someone expects it
-(bool)expectsTrigger:(NSString const *)triggerName;

@end


