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

#define SHOW_DIR_RIGHT 1
#define SHOW_NOW       0
#define HIDE_NOW       0
#define SHOW_DIR_LEFT -1

@interface TrackView : View<CaresDeeply>

@property (nonatomic,strong) NSNumber * menuIsOver;

// Derived classes implement this
-(void)createNode:(NSDictionary *)params;

-(void)showFromDir:(int)dir;
-(void)hideToDir:(int)dir;

-(void)settingsGoingAway:(SettingsVC *)vc;
-(NSArray *)getSettings; // array of SettingsDescriptor

@end
