//
//  SoundMan.h
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Sound.h"

@interface SoundMan : NSObject

-(void)wakeup;
-(void)goAway;
-(void)update:(NSTimeInterval)dt;

-(Sound*)getSound:(const char *)fileName;

-(void *)getSystem;

@end
