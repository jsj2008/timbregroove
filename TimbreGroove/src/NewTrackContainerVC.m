//
//  NewTrackContainerVC.m
//  TimbreGroove
//
//  Created by victor on 2/3/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "NewTrackContainerVC.h"
#import "NewTrackPicker.h"

@interface NewTrackContainerVC ()

@end

@implementation NewTrackContainerVC

-(void)viewDidLoad
{
    self.pickerVC.delegate = self.delegate;
}

-(NewTrackPicker *)pickerVC
{
    return self.childViewControllers[0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onCancel:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        ;
    }];
}
@end
