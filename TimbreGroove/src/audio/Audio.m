//
//  Audio.m
//  TimbreGroove
//
//  Created by victor on 2/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Audio.h"
#import "Mixer.h"

@interface Audio () {
    Mixer * _mixer;
}

@end
@implementation Audio
- (id)init
{
    self = [super init];
    if (self) {
        _mixer = [Mixer sharedInstance];
    }
    return self;
}
-(void)loadAudioFromConfig:(ConfigAudioProfile *)config
{
    
}
-(NSDictionary *)getParameters
{
    return [_mixer getParameters];
}
@end
