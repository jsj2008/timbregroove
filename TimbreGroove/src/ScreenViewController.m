//
//  TGUIViewController.m
//  TimbreGroove
//
//  Created by victor on 2/1/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "ScreenViewController.h"
#import "TGTypes.h"
#import "GraphCollection.h"
#import "Graph.h"
#import "GraphView.h"

#import "NewTrackPicker.h"
#import "NewTrackContainerVC.h"

@interface ScreenViewController () {
    bool _seenMenu;
    bool _started;
    bool _menusShowing;
    GraphCollection * _graphs;
    GLKViewController * _graphVC;
    CGSize _viewSz;
}

@end

@implementation ScreenViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _graphs = [GraphCollection new];
}

-(void)viewDidLayoutSubviews
{
    if( !_started )
    {
        for( UIViewController * vc in self.childViewControllers )
        {
            if( [vc.title isEqualToString:@"graphVC"] )
            {
                _graphVC = (GLKViewController*)vc;
                GraphView * view = (GraphView *)_graphVC.view;
                view.frame = _frontTrackContainer.bounds;
                _viewSz = view.frame.size;
                if( !_started )
                {
                    [self performSelector:@selector(performTransition:)
                               withObject:@{@"instanceClass":@"Text"}
                               afterDelay:0.25];
                    
                    _started = true;
                }
            }
        }
    }
    NSLog(@"LAYOUT");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)toggleMenus
{
    CGRect bottomRC = _toolBar.frame;
    CGRect topRC    = _menuContainer.frame;
    
    _menusShowing = topRC.origin.y == 0;
    
    if( _menusShowing )
    {
        bottomRC.origin.y = self.view.frame.size.height;
        topRC.origin.y = -topRC.size.height;
    }
    else
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
                         NSLog(@"Menus set to: %d",(int)_menusShowing);
                     }];
}

- (void)performTransition:(NSDictionary *)params
{
    [self performTransitionWithGraph:nil orParams:params];
}

- (void)performTransitionWithGraph:(Graph*)graph
{
    [self performTransitionWithGraph:graph orParams:nil];    
}

- (void)performTransitionWithGraph:(Graph*)graph orParams:(NSDictionary *)params
{
    CGRect org = _frontTrackContainer.frame;
    CGRect offscreen = org;
    offscreen.origin.x = org.size.width;
    
    [UIView animateWithDuration:1.0
                     animations:^{
                         _frontTrackContainer.frame = offscreen;
                     }
                     completion:^(BOOL finished){
                         
                         _graphVC.paused = YES;
                         
                         Graph * g;
                         
                         if( params )
                         {
                             g = [_graphs createGraphBasedOnNodeType:params
                                                                    withViewSize:_viewSz];
                         }
                         else
                         {
                             g = graph;
                         }
                         
                         ((GraphView *)_graphVC.view).graph = g;
                         _graphVC.paused = NO;
                         
                         [UIView animateWithDuration:1.0
                                          animations:^{
                                              _frontTrackContainer.frame = org;
                                          }
                                          completion:^(BOOL finished){
                                          }];
                          
                     }];
    
}

- (IBAction)dblTapForMenus:(UITapGestureRecognizer *)sender
{
    [self toggleMenus];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if( [segue.identifier isEqualToString:@"newTrack"] )
    {
        ((NewTrackContainerVC *)segue.destinationViewController).delegate = self;
    }
}

-(void)NewTrack:(NewTrackContainerVC *)vc selection:(NSDictionary *)params
{
    NSDictionary * p = params[@"userData"];
    [vc.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [self performSelector:@selector(performTransition:) withObject:p afterDelay:0.25];
    }];
    
}

@end
