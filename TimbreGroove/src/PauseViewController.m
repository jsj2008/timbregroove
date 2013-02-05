//
//  PauseViewController.m
//  TimbreGroove
//
//  Created by victor on 2/4/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "PauseViewController.h"

@interface PauseViewController ()

@end

@implementation PauseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)resume:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        ;
    }];
    [self.delegate PauseViewController:self resume:YES];
}
@end
