//
//  TrackView+Sound.h
//  TimbreGroove
//
//  Created by victor on 12/24/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TrackView.h"
@class Sound;

@interface TrackView (Sound)
- (void)showAndPlay:(int)side;
- (void)hideAndFade:(int)side;
- (void)showSceneAndPlay;
- (void)showSceneAndSync:(unsigned int)delay;
- (void)hideSceneAndFade;
@end
