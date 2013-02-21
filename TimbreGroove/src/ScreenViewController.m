//
//  TGUIViewController.m
//  TimbreGroove
//
//  Created by victor on 2/1/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Global.h"
#import "Config.h"
#import "Scene.h"
#import "Names.h"

#import "TGTypes.h"
#import "Graph.h"
#import "GraphView.h"

#import "NewScenePicker.h"
#import "SettingsVC.h"
#import "PauseViewController.h"
#import "NewSceneViewController.h"

@interface ScreenViewController : UIViewController < NewSceneDelegate,
                                                        SettingVCDelegate,
                                                        PauseViewDelegate>
{
    NSMutableArray * _scenes;
    
    int _postDeleteSceneIndex;
    
    GLKViewController * _graphVC;
    Global * _global;

    Graph * _utilityGraph;
    Graph * _stowedDisplayGraph;
    
}

@property (weak, nonatomic) IBOutlet UIView *graphContainer;
@property (weak, nonatomic) IBOutlet UIView *menuContainer;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;
@property (weak, nonatomic) IBOutlet UIPageControl *pager;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *trashCan;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *recordButton;
- (IBAction)changePage:(id)sender;
- (IBAction)toolbarSlider:(UISlider *)sender;
- (IBAction)audioPanel:(UIButton *)sender;
- (IBAction)trash:(UIBarButtonItem *)sender;
- (IBAction)record:(UIBarButtonItem *)sender;
- (IBAction)dblTapForMenus:(UITapGestureRecognizer *)sender;
@end

@implementation ScreenViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _postDeleteSceneIndex = -1;
    // force some global instializations
    [Config sharedInstance];
    
    _global = [Global sharedInstance];

    _scenes = [NSMutableArray new];
    
    [_global addObserver:self
              forKeyPath:(NSString *)kGlobalRecording
                 options:NSKeyValueObservingOptionNew
                 context:NULL];
    
    [_global addObserver:self
              forKeyPath:(NSString *)kGlobalScene
                 options:NSKeyValueObservingOptionNew
                 context:NULL];

}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if( [kGlobalRecording isEqualToString:keyPath] )
    {
        if( _global.recording )
        {
            _recordButton.tintColor = [UIColor redColor];
        }
        else
        {
            _recordButton.tintColor = [UIColor purpleColor];
        }
    }
    else if( [kGlobalScene isEqualToString:keyPath] )
    {
        [self performSelector:@selector(performTransition:)
                   withObject:_global.scene.graph
                   afterDelay:0.12];
    }
}

-(void)viewDidLayoutSubviews
{
    if( !_global.scene )
    {
        for( UIViewController * vc in self.childViewControllers )
        {
            if( [vc.title isEqualToString:@"graphVC"] )
            {
                _graphVC = (GLKViewController*)vc;
                _graphVC.view.frame = _graphContainer.bounds;
                _global.graphViewSize = _graphVC.view.frame.size;
                [self createAScene:[Config sharedInstance].defaultScene];
                break;
            }
        }
    }
}

- (void)createAScene:(ConfigScene *)config
{
    Scene * scene = [Scene sceneWithConfig:config];
    [_scenes addObject:scene];
    _global.scene = scene;
}

- (void)deleteScene
{
    [_scenes removeObject:_scenes[_postDeleteSceneIndex]];
    _pager.numberOfPages = [_scenes count];
    _pager.currentPage = 0;
    _postDeleteSceneIndex = -1;
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
        _trashCan.enabled = _scenes.count > 1;
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


- (void)performTransition:(Graph*)graph
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
                         _graphVC.paused = YES;
                         ((GraphView *)_graphVC.view).graph = graph;
                         _graphVC.paused = NO;
                         
                         [UIView animateWithDuration:speed
                                          animations:^{
                                              _graphContainer.frame = org;
                                          }
                                          completion:^(BOOL finished){
                                              if( _postDeleteSceneIndex != -1 )
                                              {
                                                  [self deleteScene];
                                                  [self performSelector:@selector(toggleMenus)
                                                             withObject:nil
                                                             afterDelay:0.1];
                                              }
                                          }];
                     }];
}

- (void)performUtilityTransitionWithGraph:(Graph*)graph
{
    CGRect org = _graphContainer.frame;
    CGRect offscreen = org;
    offscreen.origin.y = org.size.height;
    
    float speed = 0.4;
    
    [UIView animateWithDuration:speed
                     animations:^{
                         _graphContainer.frame = offscreen;
                     }
                     completion:^(BOOL finished){
                         Graph * g = graph;
                         ((GraphView *)_graphVC.view).graph = g;
                         [UIView animateWithDuration:speed
                                          animations:^{
                                              _graphContainer.frame = org;
                                          }
                                          completion:^(BOOL finished){
                                              _global.scene.graph = g;
                                          }];
                         
                     }];
    
}

- (IBAction)changePage:(id)sender
{
    _global.scene = _scenes[_pager.currentPage];
}

- (IBAction)toolbarSlider:(UISlider *)sender
{
    [_global.scene setTrigger:kTriggerMainSlider value:sender.value];
}

- (IBAction)audioPanel:(UIButton *)sender
{
    if( _utilityGraph )
    {
        [self performUtilityTransitionWithGraph:_stowedDisplayGraph];
        _utilityGraph = nil;
        _stowedDisplayGraph = nil;
    }
    else
    {
        _stowedDisplayGraph = _global.scene.graph;
        _utilityGraph = [[Graph alloc] init];
        ConfigGraphicElement * config = [[Config sharedInstance] getGraphicElement:kConfigEQPanel];
        [_utilityGraph createTopLevelNodeWithConfig:config andViewSize:_global.graphViewSize];
        [self performUtilityTransitionWithGraph:_utilityGraph];
    }
}

- (IBAction)trash:(UIBarButtonItem *)sender
{
    _postDeleteSceneIndex = _pager.currentPage;
    int i = _postDeleteSceneIndex ? 0 : 1;
    _global.scene = _scenes[i];
}

- (IBAction)record:(UIBarButtonItem *)sender {
    Global * g = _global;
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
        ((NewSceneViewController *)segue.destinationViewController).delegate = self;
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

-(void)NewScene:(NewSceneViewController *)vc selection:(ConfigScene *)sceneConfig
{
    [vc.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [self performSelector:@selector(createAScene:) withObject:sceneConfig afterDelay:0.25];
    }];
    
}

-(void)PauseViewController:(PauseViewController *)pvc resume:(BOOL)ok
{
    _graphVC.paused = NO;
}
@end
