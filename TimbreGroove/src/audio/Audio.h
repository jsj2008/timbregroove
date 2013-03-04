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
@class Scene;

@interface Audio : NSObject {
    @protected
    NSMutableDictionary * _instruments;
}
+(id)audioFromConfig:(ConfigAudioProfile *)config;
-(void)loadAudioFromConfig:(ConfigAudioProfile *)config;
-(void)getParameters:(NSMutableDictionary *)putHere;
-(void)getSettings:(NSMutableArray *)putHere;
-(void)update:(NSTimeInterval)dt scene:(Scene *)scene;

-(void)play;
-(void)pause;

// derived classes
-(void)start;

@end
