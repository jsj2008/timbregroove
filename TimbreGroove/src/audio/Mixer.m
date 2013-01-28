//
//  Mixer.m
//  TimbreGroove
//
//  Created by victor on 1/27/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Mixer.h"
#import <AVFoundation/AVFoundation.h>

static Mixer * __sharedMixer;

@implementation Sound

-(id)initWithContentsOfURL:(NSURL *)url 
{
    NSError * error;
    if( (self = [super initWithContentsOfURL:url error:&error]))
    {
        if( error )
        {
            NSLog(@"Error loading sound file %@ (URL: %@)",error.localizedDescription,url);
            exit(-1);
        }
    }
    
    return self;
}

@end
@interface Mixer () {
}
@end

@implementation Mixer

+(Mixer *)sharedInstance
{
    @synchronized (self) {
        if( !__sharedMixer )
            __sharedMixer = [Mixer new];
    }
    return __sharedMixer;
}

-(Sound *)getSound:(const char *)name
{
    NSURL *loopURL   = [[NSBundle mainBundle] URLForResource: @(name)
                                               withExtension: @"aif"];
    
    Sound * sound = [[Sound alloc] initWithContentsOfURL:loopURL];
    
    return sound;
}

@end
