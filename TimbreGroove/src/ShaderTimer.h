//
//  ShaderTimer.h
//  TimbreGroove
//
//  Created by victor on 4/18/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Painter.h"

typedef enum ShaderTimeType {
    kSTT_None,
    kSTT_Custom,     // u_time is allocated but you decide how/when to write to it
    kSTT_Timer,      // self.timer is sent every update, you decide when to 0 it out
    kSTT_CountDown,  // self.countDownBase - self.timer as long as result is >= 0
    kSTT_Total       // self.totalTime is sent every update
} ShaderTimeType;

@interface ShaderTimer : NSObject<ShaderFeature>
@property (nonatomic) NSTimeInterval countDownBase;
@property (nonatomic) ShaderTimeType timerType;
@end
