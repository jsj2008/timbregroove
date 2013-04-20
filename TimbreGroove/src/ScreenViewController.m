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
#import "Audio.h"

#import "NewScenePicker.h"
#import "SettingsVC.h"
#import "PauseViewController.h"
#import "NewSceneViewController.h"

#import "SoundSystem+Diag.h"

@interface ScreenViewController : UIViewController < NewSceneDelegate,
                                                        SettingVCDelegate,
                                                        PauseViewDelegate>
{
    NSMutableArray * _scenes;
    
    int _postDeleteSceneIndex;
    
    GLKViewController * _graphVC;
    Global * _global;

    id _modalUtility;
    
    FloatParamBlock _mainSliderTrigger;
    IntParamBlock   _playTrigger;
    
    NSString * _recordObserver;
    
    int _indexOfPlayPause;
    UIBarButtonItem * _realPlay;
    UIBarButtonItem * _pause;
    
}

@property (nonatomic,strong) Scene * currentScene;

@property (weak, nonatomic) IBOutlet UIView *graphContainer;
@property (weak, nonatomic) IBOutlet UIView *audioToolbar;
@property (weak, nonatomic) IBOutlet UIToolbar *utilityToolBar;
@property (weak, nonatomic) IBOutlet UIPageControl *pager;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *trashCan;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *recordButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *playButton;
@property (weak, nonatomic) IBOutlet UIView *menuAreaView;
- (IBAction)closeAudioMenu:(UIBarButtonItem *)sender;
- (IBAction)changePage:(id)sender;
- (IBAction)toolbarSlider:(UISlider *)sender;
- (IBAction)audioPanel:(UIButton *)sender;
- (IBAction)trash:(UIBarButtonItem *)sender;
- (IBAction)play:(UIBarButtonItem *)sender;
- (IBAction)record:(UIBarButtonItem *)sender;
- (IBAction)showMenu:(UITapGestureRecognizer *)sender;
@end

@implementation ScreenViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    TGSetLogLevel( LLShitsOnFire | LLMeshImporter | LLObjLifetime | LLGLResource);
    
    _postDeleteSceneIndex = -1;
    // force some global instializations
    [Config sharedInstance];
    
    _global = [Global sharedInstance];

    _scenes = [NSMutableArray new];
    
    BKSenderBlock recordChanger = ^(id sender) {
        if( _global.recording )
        {
            _recordButton.tintColor = [UIColor redColor];
        }
        else
        {
            _recordButton.tintColor = [UIColor purpleColor];
        }
    };
    
    _recordObserver = [_global addObserverForKeyPath:(NSString *)kGlobalRecording
                                                task:recordChanger];
    
}

-(void)setCurrentScene:(Scene *)currentScene
{
    if( _currentScene )
        [_currentScene pause];
    
    _currentScene = currentScene;
    [_currentScene activate];
    [self performSelector:@selector(performTransition:)
               withObject:currentScene
               afterDelay:0.12];
    
    _mainSliderTrigger = [currentScene.triggers getFloatTrigger:kTriggerMainSlider];
    _playTrigger       = [currentScene.triggers getIntTrigger:kTriggerPlayButton];
}

-(void)viewDidLayoutSubviews
{
    if( !_currentScene )
    {
        _realPlay = self.playButton;
        _pause = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause
                                                  target:self
                                                  action:@selector(pause:)];
        int i = 0;
        for( UIBarButtonItem * bbi in self.utilityToolBar.items )
        {
            if( bbi == _realPlay )
            {
                _indexOfPlayPause = i;
                break;
            }
            ++i;
        }
        
        for( UIViewController * vc in self.childViewControllers )
        {
            if( [vc.title isEqualToString:@"graphVC"] )
            {
                _graphVC = (GLKViewController*)vc;
                _graphVC.view.frame = _graphContainer.bounds;
                _global.graphViewSize = _graphVC.view.frame.size;
                [self createAScene:[Config defaultScene]];
                break;
            }
        }
    }
}

- (void)createAScene:(ConfigScene *)config
{
    Scene * scene = [Scene sceneWithConfig:config];
    [_scenes addObject:scene];
    self.currentScene = scene;
    _pager.numberOfPages = [_scenes count];
}

- (void)deleteScene
{
    Scene * scene = _scenes[_postDeleteSceneIndex];
    [_scenes removeObject:scene];
    [scene decomission];
    scene = nil;
    
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
    CGRect bottomRC = _utilityToolBar.frame;
    CGRect topRC    = _audioToolbar.frame;
    
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
                         _utilityToolBar.frame = bottomRC;
                         _audioToolbar.frame = topRC;
                     }
                     completion:^(BOOL finished){
                     }];
}


- (void)performTransition:(Scene *)scene
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
                         GraphView * gview = (GraphView *)_graphVC.view;
                         gview.scene = scene;
                         _graphVC.paused = NO;
                         _pager.currentPage = [_scenes indexOfObject:_currentScene];
                         
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

- (void)performUtilityTransitionWithConfig:(ConfigGraphicElement *)cge
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
                         if( cge )
                         {
                             _modalUtility = [_currentScene.graph loadFromConfig:cge
                                                                     andViewSize:_graphContainer.frame.size
                                                                           modal:true];
                         }
                         else
                         {
                             [_currentScene.graph removeChild:_modalUtility];
                             _modalUtility = nil;
                         }
                         [UIView animateWithDuration:speed
                                          animations:^{
                                              _graphContainer.frame = org;
                                          }
                                          completion:^(BOOL finished){
                                          }];
                         
                     }];
    
}

- (IBAction)closeAudioMenu:(UIBarButtonItem *)sender {
    [self toggleMenus];
}

- (IBAction)changePage:(id)sender
{
    self.currentScene = _scenes[_pager.currentPage];
}

- (IBAction)toolbarSlider:(UISlider *)sender
{
    if( _mainSliderTrigger )
        _mainSliderTrigger(sender.value);
}

- (IBAction)audioPanel:(UIButton *)sender
{
    ConfigGraphicElement * cge = nil;
    if( !_modalUtility )
        cge = [[Config sharedInstance] getGraphicElement:@"eqcube"];
    [self performUtilityTransitionWithConfig:cge];
}

- (IBAction)trash:(UIBarButtonItem *)sender
{
    _postDeleteSceneIndex = _pager.currentPage;
    int i = _postDeleteSceneIndex ? 0 : 1;
    self.currentScene = _scenes[i];
}

-(void)replaceObjectInUtilityToolBarAtIndex:(NSUInteger)index withObject:(id)object
{
    NSMutableArray * barItems = [NSMutableArray arrayWithArray:self.utilityToolBar.items];
    barItems[index] = object;
    [self.utilityToolBar setItems:barItems animated:YES];
    
}
- (void)pause:(UIBarButtonItem *)sender
{
    if( _playTrigger )
    {
        _playTrigger(0);
        [self replaceObjectInUtilityToolBarAtIndex:_indexOfPlayPause withObject:_realPlay];
    }
}

- (IBAction)play:(UIBarButtonItem *)sender
{
    if( _playTrigger )
    {
        _playTrigger(1);
        [self replaceObjectInUtilityToolBarAtIndex:_indexOfPlayPause withObject:_pause];
    }
}

- (IBAction)record:(UIBarButtonItem *)sender {
    Global * g = _global;
    g.recording = !g.recording;
}

- (IBAction)showMenu:(UITapGestureRecognizer *)sender
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
        [_currentScene pause];
        _graphVC.paused = YES;
        ((PauseViewController *)segue.destinationViewController).delegate = self;
    }
    else
    {
        TGLog(LLJustSayin, @"Doing seque called; %@", segue.identifier);
    }
}

-(void)SettingsVC:(SettingsVC *)vc getSettings:(NSMutableArray *)array
{
    [_currentScene getSettings:array];
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
    [_currentScene activate];
    _graphVC.paused = NO;
}
@end
