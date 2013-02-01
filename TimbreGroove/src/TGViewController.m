//
//  TGViewController.m
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGViewController.h"
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

@interface TGViewController () {
    MenuView  * _menuView;
    bool _dawView;
    TrackView * _currentTrackView;
    TrackView * _rootView;
}

@property (strong, nonatomic) EAGLContext *context;

@end

@implementation TGViewController

- (void)viewDidLoad
{
    CMSG("viewDidLoad");
    
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
    
    Factory * globalFactory = [Factory sharedInstance];
    globalFactory.delegate = self;
    
    self.preferredFramesPerSecond = 60;
    
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

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    if( !_currentTrackView )
    {
        glClearColor(0.2f, 0.2f, 0.2f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    }
    
    for (View * view in self.view.subviews )
    {
        if( !view.isHidden )
        {
            [view setupGL];            
            [view display];
        }
    }
}

#pragma mark - this app View delegate methods

-(void)tgViewWillAppear:(View *)view
{
    if( [view isKindOfClass:[TrackView class]] )
    {
        _currentTrackView = (TrackView *)view;
        NSLog(@"Current view set to %@",_currentTrackView);
        if( !_rootView )
            _rootView = _currentTrackView;
    }
    else
    {
        NSLog(@"Menu is appearing: %@",view);
    }
}

-(void)tgViewWillDisappear:(View *)view;
{
    
}

-(void)tgViewIsFullyVisible:(View *)view
{
    
}

-(void)tgViewIsOutofSite:(View *)view
{
    if( view == _menuView )
    {
        _menuView = nil;
        view.markedForDelete = true;
    }
    else if( view == _currentTrackView )
    {
        // find the next available track view to display
        for( TrackView * tv in [self getTrackViews] )
        {
            if( tv != view )
            {
                [tv showFromDir:SHOW_DIR_LEFT];
                break;
            }
        }
    }
    
    if( view.markedForDelete )
    {
        [view.graph cleanChildren];
        [view removeFromSuperview];
    }
    
    /*
    if( resetContext && _currentTrackView )
        // this is probably not the right place but at
        // some point we have to notify OpenGL that we
        // are switching contexts back to our current
        // view thingy
        [_currentTrackView setupGL];
    */
}

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
    [mview addDelegate:self];
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

- (NSNumber *)closeAllMenus
{
    bool closed = false;
    for( MenuView * view in [self getViewsOfType:[MenuView class]] )
    {
        if( !view.hidden )
        {
            view.markedForDelete = true;
            [view hideToDir:HIDE_NOW];
            closed = true;
        }
    }

    return @(closed);
}

-(void)toggleMenuView
{
    if( !_menuView )
    {
        _menuView = [self Menu:nil makeMenuView:nil];
        [_menuView showFromDir:SHOW_DIR_LEFT];
    }
    else if( _menuView.hidden )
    {
        [_menuView showFromDir:SHOW_DIR_LEFT];
    }
    else
    {
        [self closeAllMenus];        
    }
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
    [self closeAllMenus];
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
    
    if( _currentTrackView )
        [_currentTrackView hideToDir:SHOW_DIR_LEFT];
    [tv showFromDir:SHOW_DIR_RIGHT];
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
    [tview addDelegate:self];
    
    [view addSubview:tview];
    [view sendSubviewToBack:tview];
    [tview setupGL]; // required for calls made during initialization
    return tview;
}

-(void)Factory:(Factory *)factory deleteNode:(NSDictionary *)options
{
    [self closeAllMenus];
    _currentTrackView.markedForDelete = true;
    [_currentTrackView shrinkToNothing];
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


- (void)slideToPrevView
{
    if( !_currentTrackView )
        return;
    NSArray * arr = [self getTrackViews];
    int max = [arr count] - 1;
    int i = 0;
    for( TrackView * view in arr )
    {
        if( view == _currentTrackView )
        {
            if( i < max )
            {
                TrackView * next = arr[i+1];
                [_currentTrackView hideToDir:SHOW_DIR_RIGHT];
                _currentTrackView = nil;
                [next showFromDir:SHOW_DIR_LEFT];
            }
            break;
        }
        ++i;
    }
}

-(void)slideToNextView
{
    if( !_currentTrackView )
        return;
    
    TrackView * prev = nil;
    for( TrackView * view in [self getTrackViews] )
    {
        if( view == _currentTrackView )
        {
            if( prev )
            {
                [_currentTrackView hideToDir:SHOW_DIR_LEFT];
                _currentTrackView = nil;
                [prev showFromDir:SHOW_DIR_RIGHT];
            }
            break;
        }
        prev = view;
    }
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
    
    [self closeAllMenus];
    
    [super prepareForSegue:segue sender:sender];
    
    NSArray * settings = [_currentTrackView getSettings];
    SettingsVC * svc = (SettingsVC *)segue.destinationViewController;
    svc.settings = settings;
    svc.caresDeeply = _currentTrackView;
    
}

#pragma mark - Gestures


- (IBAction)onTap:(UITapGestureRecognizer *)sender {
    [self toggleMenuView];
}

- (IBAction)rightSwipe:(UISwipeGestureRecognizer *)sgr
{
    if( sgr.state != UIGestureRecognizerStateEnded )
    {
        return;
    }
    [self closeAllMenus];
    
    [self slideToPrevView];
}

- (IBAction)leftSwipe:(UISwipeGestureRecognizer *)sgr
{
    if( sgr.state != UIGestureRecognizerStateEnded )
    {
        return;
    }
    [self closeAllMenus];
    
    [self slideToNextView];
}

- (IBAction)pinch:(UIPinchGestureRecognizer *)pgr
{
    [self closeAllMenus];
    
    if( pgr.scale < 1.0f )
    {
        if( !_dawView )
        {
            [self makeDawView];
            _dawView = true;
        }
    }
    else
    {
        if( _dawView )
        {
            [self unMakeDawView];
            _dawView = false;
        }
    }
}

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
