//
//  SoundPool.h
//  TimbreGroove
//
//  Created by victor on 1/7/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Sound;

@interface SoundPool : NSObject
+(id)sharedInstance;

-(Sound*)getSound:(NSDictionary *)params;

@end
