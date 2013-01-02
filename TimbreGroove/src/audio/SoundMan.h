//
//  SoundMan.h
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Sound.h"
#import "fmod.h" // sigh, for FMOD_SYSTEM

@interface SoundMan : NSObject

+(SoundMan *)sharedInstance;

-(void)wakeup;
-(void)goAway;
-(void)update:(NSTimeInterval)dt;
//-(void)syncAll:(FMOD_TIMEUNIT)tu;
-(Sound*)getSound:(const char *)fileName;

-(FMOD_SYSTEM *)getSystem;
-(void)dumpTime;

@end
