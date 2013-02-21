//
//  NewSceneContainerVC.h
//  TimbreGroove
//
//  Created by victor on 2/3/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NewScenePicker.h"
@class NewScenePicker;
@protocol NewSceneDelegate;

@interface NewSceneViewController : UIViewController
- (IBAction)onCancel:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic,readonly) NewScenePicker * pickerVC;
@property (nonatomic,weak) id<NewSceneDelegate> delegate;
@end
