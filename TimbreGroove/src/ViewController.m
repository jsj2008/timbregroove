//
//  TGUIViewController.m
//  TimbreGroove
//
//  Created by victor on 2/1/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "ViewController.h"
#import "TrackController.h"
#import "TGTypes.h"

@interface ViewController () {
    TrackController * _trackController;
    GLKView * _trackView;
    GLKView * _menuView;
    bool _started;
    bool _menusShowing;
}

@end

@implementation ViewController

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
                _trackController = (TrackController*)vc;
                vc.view.frame = _containerView.bounds;
                [((TGBaseViewController *)vc) startGL];
            }
            else if( [vc.title isEqualToString:@"menuVC"] )
            {
                vc.view.frame = _menuContainer.bounds;
                [((TGBaseViewController *)vc) startGL];
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

- (IBAction)dblTapForMenus:(UITapGestureRecognizer *)sender
{
    CGRect bottomRC = _bottomMenuBar.frame;
    bottomRC.origin.y = self.view.frame.size.height;
    if( _bottomMenuBar.hidden == YES )
    {
        _bottomMenuBar.frame = bottomRC;
        _bottomMenuBar.hidden = NO;
    }

    if( !_menusShowing )
    {
        bottomRC.origin.y -= bottomRC.size.height;
    }
    
    [UIView animateWithDuration:1.0
                     animations:^{
                         _bottomMenuBar.frame = bottomRC;
                     }
                     completion:^(BOOL finished){
                         _menusShowing = !_menusShowing;
                     }];
}
@end
