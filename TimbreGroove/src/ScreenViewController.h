//
//  TGUIViewController.h
//  TimbreGroove
//
//  Created by victor on 2/1/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NewTrackPicker.h"

@interface ScreenViewController : UIViewController<NewTrackDelegate>

@property (weak, nonatomic) IBOutlet UIView *frontTrackContainer;
@property (weak, nonatomic) IBOutlet UIView *menuContainer;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;
@property (weak, nonatomic) IBOutlet UIView *backTrackContainer;


- (IBAction)dblTapForMenus:(UITapGestureRecognizer *)sender;

@end
