//
//  Sound.h
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SoundMan;

@interface TGSound : NSObject
-(id)initWithFile:(const char *)fileName soundMan:(SoundMan*)soundMan;
-(void)play;
-(void)mute;
-(void)releaseResource;
@end
