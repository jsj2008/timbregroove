//
//  Audio.h
//  TimbreGroove
//
//  Created by victor on 2/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"

@class ConfigAudioProfile;

@interface Audio : NSObject {
    @protected
    NSMutableDictionary * _instruments;
}
+(id)audioFromConfig:(ConfigAudioProfile *)config;
-(void)loadAudioFromConfig:(ConfigAudioProfile *)config;
-(void)start;
-(NSDictionary *)getParameters;
-(void)update:(NSTimeInterval)dt mixerUpdate:(MixerUpdate *)mixerUpdate;
@end
