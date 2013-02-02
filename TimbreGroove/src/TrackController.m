//
//  TGViewController.m
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TrackController.h"
#import "MenuView.h"
#import "MenuItem.h"
#import "Factory.h"
#import "TrackView.h"
#import "Graph.h"
#import "SettingsVC.h"

#if 1
#define CMSG(s) NSLog(@s)
#else
#define CMSG(s)
#endif


@implementation TrackController

-(void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)startGL
{
    [self setupGL];
    [self createNode:@{@"instanceClass":@"PoolScreen"}];
}
@end


@interface OLDTrackContrller : GLKViewController<MenuViewDelegate,FactoryDelegate>


@end
@interface OLDTrackContrller () {
    MenuView  * _menuView;
    bool _dawView;
    TrackView * _currentTrackView;
    TrackView * _rootView;
}

@property (strong, nonatomic) EAGLContext *context;

@end

@implementation OLDTrackContrller

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
    
    Factory * globalFactory = [Factory sharedInstance];
    globalFactory.delegate = self;
    
    self.preferredFramesPerSecond = 60;
}

-(void)startGL
{
    [self createTrackAndNode:@{@"instanceView":@"TrackView",@"instanceClass":@"PoolScreen"}];
}

- (void)viewWillAppear:(BOOL)animated
{
    CMSG("viewWillAppear");
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    CMSG("viewWillDisappear");
    
    [super viewWillDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
    }
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

- (void)tearDownGL
{
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;    
}

- (void)viewDidUnload
{
    _menuView = nil;
    _currentTrackView = nil;
}

-(void)dealloc
{
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    NSTimeInterval dt = self.timeSinceLastUpdate;
    for (View * view in self.view.subviews )
    {
        if( !view.hidden )
            [view update:dt];
    }
}

#pragma mark - this app View delegate methods


#pragma mark -
#pragma mark Menus

- (id)Menu:(Menu*)menu makeMenuView:(NSDictionary *)meta
{
    // 1. Calculate menu frame
    //--------------------------------
    GLKView *view = (GLKView *)self.view;
    CGRect rc = view.frame;
    rc.size.width = (float)MENU_VIEW_WIDTH;

    // 2. Setup gl context
    //--------------------------------
    EAGLContext * context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2
                                                  sharegroup:self.context.sharegroup];

    // 3. Create and init MenuView object
    //--------------------------------------------------
    MenuView * mview = [[MenuView alloc] initWithFrame:rc context:context]; // this sets .desiredFrame
    rc.origin.x = -rc.size.width; // then we move it off screen
    mview.frame = rc;
    mview.drawableDepthFormat = view.drawableDepthFormat;
    mview.backgroundColor = [UIColor clearColor];
    [view addSubview:mview];

    // 4. Trap taps for menu items
    //--------------------------------
    UITapGestureRecognizer * tgr;
    tgr = [[UITapGestureRecognizer alloc] initWithTarget:mview action:@selector(onTap:)];
    [mview addGestureRecognizer:tgr];
    
    // 5. Create the drawing menu object
    //-------------------------------------
    Menu * newMenu = [mview createMenu:meta]; // null meta will read from menus.plist
    newMenu.delegate = self;
    
    return mview;
}

- (bool)Menu:(Menu *)menu shouldEnable:(MenuItem *)mi
{
    if( [mi.name isEqualToString:@"delete_view"] )
        return !([self isRootView]);
    
    return true;
}

- (int)Menu:(Menu*)menu playMode:(MenuItem *)mi
{
    if( _currentTrackView )
        return _currentTrackView.playMode;

    return 0; // err...
}


#pragma mark -
#pragma mark DAW view managment

- (NSArray *)getTrackViews
{
    return [self getViewsOfType:[TrackView class]];
}

-(NSArray *)getViewsOfType:(Class)vClass
{
    return [self.view.subviews objectsAtIndexes:[self.view.subviews
                                                 indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                                                                return [obj isKindOfClass:vClass];
                                                            }]];
}

-(void)Factory:(Factory *)factory
    createNode:(NSDictionary *)options
{
    [self createTrackAndNode:options];
}

-(void)createTrackAndNode:(NSDictionary *)options
{
    NSString * klassName = options[@"instanceView"];
    Class klass;
    if( klassName )
        klass = NSClassFromString(klassName);
    else
        klass = [TrackView class];
    
    TrackView * tv = [self makeTrackView:klass];
    
    [tv createNode:options];
    
}

-(bool)isRootView
{
    return _currentTrackView == _rootView;
}

- (id)makeTrackView:(Class)klass
{
    GLKView *view = (GLKView *)self.view;
    CGRect rc = view.frame;

    EAGLContext * context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:self.context.sharegroup];
    TrackView * tview = [[klass alloc] initWithFrame:rc context:context];
    tview.drawableDepthFormat = view.drawableDepthFormat;
    
    [view addSubview:tview];
    [view sendSubviewToBack:tview];
    return tview;
}

-(void)Factory:(Factory *)factory deleteNode:(NSDictionary *)options
{
}

-(void)Factory:(Factory *)factory pauseToggle:(NSDictionary *)options
{
    if( _currentTrackView )
        _currentTrackView.playMode = !_currentTrackView.playMode;
}

- (void)makeDawView
{
    /*
    NSArray * trackViews = [self getTrackViews];
    NSUInteger   count = [trackViews count];
    CGRect rc = self.view.frame;
    
    unsigned int dim = 1;
    if( count <= 4 )
        dim = 2;
    else if( count <= 9 )
        dim = 3;
    else if( count <= 16 )
        dim = 4;
    unsigned int w = rc.size.width / dim;
    unsigned int h = rc.size.height / dim;
    unsigned int vcount = 0;
    for (unsigned int q = 0; q < dim && vcount < count; q++) {
        for( unsigned int r = 0; r < dim && vcount < count; r++ ) {
            TrackView * view = trackViews[vcount++];
            [view showFromDir:SHOW_DIR_LEFT];
            view.frame = rc;
            [view animateProp:"x"      targetVal:q*w hide:false];
            [view animateProp:"y"      targetVal:r*h hide:false];
            [view animateProp:"width"  targetVal:w hide:false];
            [view animateProp:"height" targetVal:h hide:false];
        }
    }
     */
}

- (void)unMakeDawView
{
    /*
    NSArray * trackViews = [self getTrackViews];
    NSUInteger   count = [trackViews count];
    CGRect rc = self.view.frame;
    for( int i = 0; i < count; i++ )
    {
        TrackView * view = trackViews[i];
        if( view == _currentTrackView )
        {
            [view animateProp:"x"      targetVal:0 hide:false];
            [view animateProp:"y"      targetVal:0 hide:false];
            [view animateProp:"width"  targetVal:rc.size.width hide:false];
            [view animateProp:"height" targetVal:rc.size.height hide:false];
        }
        else
        {
            view.frame = rc;
            [view hideToDir:HIDE_NOW];
        }
    }
     */
}



#pragma mark - Segue

-(void)Factory:(Factory *)factory
       segueTo:(NSString *)segueName
{
    [self performSegueWithIdentifier:segueName sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    CMSG("prepareForSegue");
    
    [super prepareForSegue:segue sender:sender];
    
    NSArray * settings = [_currentTrackView getSettings];
    SettingsVC * svc = (SettingsVC *)segue.destinationViewController;
    svc.settings = settings;
    svc.caresDeeply = _currentTrackView;
    
}

#pragma mark - Gestures



- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGRect rect = CGRectZero;
    
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait || toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        rect = screenRect;
        
    } else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        rect.size = CGSizeMake( screenRect.size.height, screenRect.size.width );
    }
    
    for( TrackView * view in [self getTrackViews] )
    {
        view.frame = rect;
    }
}

@end
