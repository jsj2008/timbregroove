//
//  NewTrackContainerVC.h
//  TimbreGroove
//
//  Created by victor on 2/3/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NewTrackPicker.h"
@class NewTrackPicker;
@protocol NewTrackDelegate;

@interface NewTrackContainerVC : UIViewController
- (IBAction)onCancel:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic,readonly) NewTrackPicker * pickerVC;
@property (nonatomic,weak) id<NewTrackDelegate> delegate;
@end
