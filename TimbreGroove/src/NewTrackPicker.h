//
//  NewTrackPicker.h
//  TimbreGroove
//
//  Created by victor on 2/3/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NewTrackContainerVC.h"

@class NewTrackPicker;
@class NewTrackContainerVC;

@protocol NewTrackDelegate <NSObject>

-(void)NewTrack:(NewTrackContainerVC *)picker selection:(NSDictionary *)params;

@end

@interface NewTrackPicker : UICollectionViewController <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic,weak) id<NewTrackDelegate> delegate;
@end
