//
//  TG3dObject+Sound.m
//  TimbreGroove
//
//  Created by victor on 12/24/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TG3dObject+Sound.h"
#import "Sound.h"
#import "SoundPool.h"

#import "objc/runtime.h"

static Sound * _objSound;

@implementation TG3dObject (Sound)

-(void)assignSound:(NSDictionary *)params
{
    self.sound = [[SoundPool sharedInstance] getSound:params];
}

-(Sound *)sound
{
    return (Sound *)objc_getAssociatedObject(self,&_objSound);
}

-(void)setSound:(Sound *)sound
{
    objc_setAssociatedObject(self, &_objSound, sound, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
