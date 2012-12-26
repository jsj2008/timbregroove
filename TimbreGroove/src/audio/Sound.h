//
//  Sound.h
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SoundMan;

@interface Sound : NSObject

@property (nonatomic) bool  paused;
@property (nonatomic) float volume;
@property (nonatomic) float prevVolume;

-(id)initWithFile:(const char *)fileName soundMan:(SoundMan*)soundMan;
-(void)play;
-(void)pause;
-(void)mute;
-(void)rewind;
-(void)releaseResource;
-(void)sync:(int)delay;
@end
