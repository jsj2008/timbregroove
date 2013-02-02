//
//  TGUIViewController.h
//  TimbreGroove
//
//  Created by victor on 2/1/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ScreenViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *trackContainer;
@property (weak, nonatomic) IBOutlet UIView *menuContainer;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;


- (IBAction)dblTapForMenus:(UITapGestureRecognizer *)sender;

@end
