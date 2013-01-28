//
//  TGViewController.m
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGViewController.h"
#import "MenuView.h"
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
        if( view.visible )
            [view update:dt];
    }

    [self.view setNeedsDisplay];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.2f, 0.2f, 0.2f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}


#pragma mark -
#pragma mark Menus

- (id)makeMenuView:(NSDictionary *)meta
{
    GLKView *view = (GLKView *)self.view;
    CGRect rc = view.frame;
    rc.size.width *= 0.20;
    rc.origin.x = -rc.size.width;
//  EAGLContext * context = self.context;

    EAGLContext * context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2
                                                  sharegroup:self.context.sharegroup];
    
    MenuView * mview = [[MenuView alloc] initWithFrame:rc context:context];
    mview.drawableDepthFormat = view.drawableDepthFormat;
    mview.backgroundColor = [UIColor clearColor];
    UITapGestureRecognizer * tgr;
    tgr = [[UITapGestureRecognizer alloc] initWithTarget:mview action:@selector(onTap:)];
    [mview addGestureRecognizer:tgr];
    [view addSubview:mview];
    [mview setupGL];
    Menu * menu = [mview createMenu:meta];
    menu.viewMaker = self;
    menu.menuView = mview;
    return mview;
}

- (void)closeAllMenus
{
    Class mClass = [MenuView class];
    for( UIView * view in self.view.subviews )
    {
        if( [view isKindOfClass:mClass] )
        {
            [((MenuView *)view) hide];
        }
    }
}

-(void)toggleMenuView
{
    if( !_menuView )
        _menuView = [self makeMenuView:nil];
    
    if( !_menuView.visible )
    {
        if( _currentTrackView )
            _currentTrackView.menuIsOver = [[NSNumber alloc] initWithBool:true];

        [_menuView show];
    }
    else
    {
        [self closeAllMenus];
        
        if( _currentTrackView )
            _currentTrackView.menuIsOver = [[NSNumber alloc] initWithBool:false];
    }
}

#pragma mark -
#pragma mark DAW view managment

- (NSArray *)getTrackViews
{
    NSMutableArray * arr = [NSMutableArray new];
    Class tClass = [TrackView class];
    for( View * view in self.view.subviews )
    {
        if( [view isKindOfClass:tClass] )
            [arr addObject:view];
    }
    return arr;
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
    
    [tv showFromDir:SHOW_DIR_RIGHT];
    if( _currentTrackView )
        [_currentTrackView hideToDir:SHOW_DIR_LEFT];
    _currentTrackView = tv;
    
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
    [tview setupGL];
    return tview;
}

-(void)Factory:(Factory *)factory deleteNode:(NSDictionary *)options
{
    if( !_currentTrackView )
    {
        // TODO: disable invalid menu items
        return;
    }

    [_currentTrackView shrinkToNothing:self notify:@"viewIsGone"];
}

-(void)dumpCurrentView
{
    [_currentTrackView.graph cleanChildren];
    [_currentTrackView removeFromSuperview];
    _currentTrackView = nil;
    
}
- (void)viewIsGone
{
    NSArray * trackViews = [self getTrackViews];
    for( TrackView * view in trackViews )
    {
        if( view != _currentTrackView )
        {
            [self dumpCurrentView];
            _currentTrackView = view;
            [_currentTrackView showFromDir:SHOW_NOW];
            return;
        }
    }
    [self dumpCurrentView];
}

- (void)makeDawView
{
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
}

- (void)unMakeDawView
{
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
}


- (void)slideToPrevView
{
    if( !_currentTrackView )
        return;
    
    NSArray * trackViews = [self getTrackViews];
    int count = [trackViews count];
    for( int i = 0; i < count-1; i++ )
    {
        if( trackViews[i] == _currentTrackView )
        {
            TrackView * next = trackViews[i+1];
            [next showFromDir:SHOW_DIR_LEFT];
            [_currentTrackView hideToDir:SHOW_DIR_RIGHT];
            _currentTrackView = next;
            break;
        }
    }
}

-(void)slideToNextView
{
    if( !_currentTrackView )
        return;
    
    NSArray * trackViews = [self getTrackViews];
    int count = [trackViews count];
    for( int i = 0; i < count; i++ )
    {
        if( trackViews[i] == _currentTrackView )
        {
            if( i > 0 )
            {
                TrackView * next = trackViews[i-1];
                [next showFromDir:SHOW_DIR_RIGHT];
                [_currentTrackView hideToDir:SHOW_DIR_LEFT];
                _currentTrackView = next;
            }
            break;
        }
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
    [self slideToPrevView];
}

- (IBAction)leftSwipe:(UISwipeGestureRecognizer *)sgr
{
    if( sgr.state != UIGestureRecognizerStateEnded )
    {
        return;
    }
    [self slideToNextView];
}

- (IBAction)pinch:(UIPinchGestureRecognizer *)pgr
{
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
