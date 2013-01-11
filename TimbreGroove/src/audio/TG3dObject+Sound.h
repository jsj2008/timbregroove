//
//  TG3dObject+Sound.h
//  TimbreGroove
//
//  Created by victor on 12/24/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TG3dObject.h"

#define DEFAULT_INITIAL_VOLUME 0.5f

@class Sound;

@interface TG3dObject (Sound)
@property (nonatomic,strong) Sound * sound;

-(void)assignSound:(NSDictionary *)params;

@end
