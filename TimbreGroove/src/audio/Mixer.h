//
//  Mixer.h
//  TimbreGroove
//
//  Created by victor on 1/27/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface Sound : AVAudioPlayer

@end

@interface Mixer : NSObject

+(Mixer *)sharedInstance;

-(Sound *)getSound:(const char *)name;

@end
