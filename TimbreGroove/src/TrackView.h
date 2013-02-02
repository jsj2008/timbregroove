//
//  TrackView.h
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <GLKit/GLKit.h>

#import "View.h"
#import "SettingsVC.h"


typedef enum TrackPlayMode {
    tpm_play,
    tpm_pause
} TrackPlayMode;

@interface TrackView : View<CaresDeeply>

@property (nonatomic) TrackPlayMode playMode;


-(void)settingsGoingAway:(SettingsVC *)vc;
-(NSArray *)getSettings; // array of SettingsDescriptor

@end
