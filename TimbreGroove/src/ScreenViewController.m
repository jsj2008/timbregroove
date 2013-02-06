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
#import "GraphDefinitions.h"
#import "NewTrackContainerVC.h"
#import "Global.h"

@interface ScreenViewController () {
    bool _started;

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
    
    [[Global sharedInstance] addObserver:self
                              forKeyPath:@"recording"
                                 options:NSKeyValueObservingOptionNew
                                 context:NULL];
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if( [keyPath isEqualToString:@"recording"] )
    {
        if( [Global sharedInstance].recording )
        {
            _recordButton.tintColor = [UIColor redColor];
        }
        else
        {
            _recordButton.tintColor = [UIColor purpleColor];
        }
    }
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
                _graphVC.view.frame = _graphContainer.bounds;
                _viewSz = _graphVC.view.frame.size;
                if( !_started )
                {
                    [self performSelector:@selector(performTransition:)
                               withObject:[GraphDefinitions getDefinitionForName:@"pool_element"]
                               afterDelay:0.25];
                    
                    _started = true;
                }
            }
        }
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
    CGRect topRC    = _menuContainer.frame;
    
    bool menusShowing = topRC.origin.y == 0;

    float speed = 0.75;
    
    if( menusShowing )
    {
        bottomRC.origin.y = self.view.frame.size.height;
        topRC.origin.y = -topRC.size.height;
        speed = 0.5;
    }
    else
    {
        _trashCan.enabled = _graphs.count > 1;
        bottomRC.origin.y -= bottomRC.size.height;
        topRC.origin.y = 0;
    }
    [UIView animateWithDuration:speed
                     animations:^{
                         _toolBar.frame = bottomRC;
                         _menuContainer.frame = topRC;
                     }
                     completion:^(BOOL finished){
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
    CGRect org = _graphContainer.frame;
    CGRect offscreen = org;
    offscreen.origin.x = org.size.width;
    
    float speed = 0.4;
    
    [UIView animateWithDuration:speed
                     animations:^{
                         _graphContainer.frame = offscreen;
                     }
                     completion:^(BOOL finished){
                         Graph * g;
                         
                         bool markedForDelete = false;
                         
                         if( params )
                         {
                             g = [_graphs createGraphBasedOnNodeType:params
                                                        withViewSize:_viewSz];
                             
                             _pager.numberOfPages = _graphs.count;
                             _pager.currentPage = _pager.numberOfPages - 1;
                         }
                         else if( graph )
                         {
                             g = graph;
                         }
                         else
                         {
                             unsigned int i = (unsigned int)_pager.currentPage;
                             markedForDelete = true;
                             i = i ? 0 : 1;
                             g = [_graphs graphAtIndex:i];
                         }
                         
                         _graphVC.paused = YES;
                         ((GraphView *)_graphVC.view).graph = g;
                         _graphVC.paused = NO;
                         
                         [UIView animateWithDuration:speed
                                          animations:^{
                                              _graphContainer.frame = org;
                                          }
                                          completion:^(BOOL finished){
                                              [Global sharedInstance].displayingGraph = g;
                                              if( markedForDelete )
                                              {
                                                  [_graphs removeGraphAtIndex:_pager.currentPage];
                                                  _pager.numberOfPages = _graphs.count;
                                                  _pager.currentPage = 0;
                                                  [self performSelector:@selector(toggleMenus)
                                                             withObject:nil
                                                             afterDelay:0.1];
                                              }
                                          }];
                          
                     }];
    
}

- (IBAction)changePage:(id)sender
{
    [self performTransitionWithGraph:[_graphs graphAtIndex:_pager.currentPage]];
}

- (IBAction)trash:(UIBarButtonItem *)sender
{
    [self performTransition:nil];
}

- (IBAction)record:(UIBarButtonItem *)sender {
    Global * g = [Global sharedInstance];
    g.recording = !g.recording;
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
    else if( [segue.identifier isEqualToString:@"settings"] )
    {
        ((SettingsVC *)segue.destinationViewController).delegate = self;
    }
    else if( [segue.identifier isEqualToString:@"pause"] )
    {
        _graphVC.paused = YES;
        ((PauseViewController *)segue.destinationViewController).delegate = self;
    }
    else
    {
        NSLog(@"Doing seque called; %@", segue.identifier);
    }
}

-(void)SettingsVC:(SettingsVC *)vc getSettings:(NSMutableArray *)array
{
    [array addObjectsFromArray:[(GraphView *)_graphVC.view getSettings]];
}

-(void)SettingsVC:(SettingsVC *)vc commitChanges:(NSDictionary *)settings
{
    [((GraphView *)_graphVC.view) performSelector:@selector(commitSettings)
                                       withObject:nil
                                       afterDelay:0.3];
}

-(void)NewTrack:(NewTrackContainerVC *)vc selection:(NSDictionary *)params
{
    NSDictionary * p = params[@"userData"];
    [vc.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [self performSelector:@selector(performTransition:) withObject:p afterDelay:0.25];
    }];
    
}

-(void)PauseViewController:(PauseViewController *)pvc resume:(BOOL)ok
{
    _graphVC.paused = NO;
}
@end
