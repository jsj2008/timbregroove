//
//  TGUIViewController.m
//  TimbreGroove
//
//  Created by victor on 2/1/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "ScreenViewController.h"
#import "BaseViewController.h"
#import "TGTypes.h"

@interface ScreenViewController () {
    bool _started;
    bool _menusShowing;
}

@end

@implementation ScreenViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}


-(void)viewDidLayoutSubviews
{

    if( !_started )
    {
        
        for( UIViewController * vc in self.childViewControllers )
        {
            if( [vc.title isEqualToString:@"trackVC"] )
            {
                vc.view.frame = _trackContainer.bounds;
                [(BaseViewController*)vc startGL];
            }
            else if( [vc.title isEqualToString:@"menuVC"] )
            {
                vc.view.frame = _menuContainer.bounds;
                [(BaseViewController*)vc startGL];
            }
        }
        
        _started = true;
    }
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)toggleMenus
{
    CGRect bottomRC = _toolBar.frame;
    bottomRC.origin.y = self.view.frame.size.height;
    
    CGRect topRC = _menuContainer.frame;
    topRC.origin.y = -topRC.size.height;
    
    if( _toolBar.hidden == YES )
    {
        _toolBar.frame = bottomRC;
        _toolBar.hidden = NO;
        
        _menuContainer.frame = topRC;
        _menuContainer.hidden = NO;
    }
    
    if( !_menusShowing )
    {
        bottomRC.origin.y -= bottomRC.size.height;
        topRC.origin.y = 0;
    }
    
    [UIView animateWithDuration:1.0
                     animations:^{
                         _toolBar.frame = bottomRC;
                         _menuContainer.frame = topRC;
                     }
                     completion:^(BOOL finished){
                         _menusShowing = !_menusShowing;
                         _menuContainer.hidden = !_menusShowing;
                     }];
}

- (IBAction)dblTapForMenus:(UITapGestureRecognizer *)sender
{
    [self toggleMenus];
}
@end
