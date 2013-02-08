//
//  TGUIViewController.h
//  TimbreGroove
//
//  Created by victor on 2/1/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NewTrackPicker.h"
#import "SettingsVC.h"
#import "PauseViewController.h"

@interface ScreenViewController : UIViewController < NewTrackDelegate,
                                                     SettingVCDelegate,
                                                     PauseViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *graphContainer;
@property (weak, nonatomic) IBOutlet UIView *menuContainer;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;
@property (weak, nonatomic) IBOutlet UIPageControl *pager;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *trashCan;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *recordButton;
- (IBAction)changePage:(id)sender;
- (IBAction)volumeChanged:(UISlider *)sender;
- (IBAction)trash:(UIBarButtonItem *)sender;
- (IBAction)record:(UIBarButtonItem *)sender;
- (IBAction)dblTapForMenus:(UITapGestureRecognizer *)sender;
@end
