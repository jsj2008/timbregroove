//
//  TrackView.h
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <GLKit/GLKit.h>

#import "View.h"

#define SHOW_DIR_RIGHT 1
#define SHOW_DIR_LEFT -1

@interface TrackView : View

-(void)createNode:(NSDictionary *)params;

-(void)showFromDir:(int)dir;
-(void)hideToDir:(int)dir;

-(NSArray *)getSettings; // array of SettingsDescriptor

@end
