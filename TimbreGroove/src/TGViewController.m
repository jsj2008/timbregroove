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
#import "SoundMan.h"
#import "TG3dObject+Sound.h"
#import "TrackView+Sound.h"

@interface TGViewController () {
    MenuView  * _menuView;
    bool _dawView;
    TrackView * _showingTrackView;
    SoundMan * _sound;
}

@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

@end

@implementation TGViewController

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
    
    _sound = [SoundMan new];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [_sound wakeup];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [_sound goAway];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
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
    // ?
    //[EAGLContext setCurrentContext:self.context];
    
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    NSTimeInterval dt = self.timeSinceLastUpdate;
    for (View * view in self.view.subviews ) {
        [view update:dt];
    }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.2f, 0.2f, 0.2f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [_sound update:self.timeSinceLastDraw];
}


#pragma mark -
#pragma mark Menus

- (id)makeMenuView:(NSDictionary *)meta
{
    GLKView *view = (GLKView *)self.view;
    CGRect rc = view.frame;
    rc.size.width *= 0.20;
    rc.origin.x = -rc.size.width;
    EAGLContext * context = view.context; // [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
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

- (void)Factory:(Factory *)factory onNodeCreated:(Node *)node
{
    [self closeAllMenus];
    
    NSArray * trackViews = [self getTrackViews];
    
    int numObjs = [trackViews count];
    
    static int currSound;
    static const char * sounds[3] = {
        "TGAmb1-32k.aif",
        "TGAmb2-32k.aif",
        "TGAmb3-32k.aif"
    };
    TG3dObject * obj  =(TG3dObject *)node;
    obj.sound = [_sound getSound:sounds[currSound]];
    currSound = (currSound + 1) % 3;
    
    TrackView * tv = [self makeTrackView:obj];
    tv.trackNumber = numObjs;
    [tv showAndPlay:SHOW_DIR_RIGHT];
    if( _showingTrackView )
        [_showingTrackView hideAndFade:SHOW_DIR_LEFT];
    _showingTrackView = tv;
}

- (id)makeTrackView:(Node *)starterObj
{
    GLKView *view = (GLKView *)self.view;
    CGRect rc = view.frame;
    EAGLContext * context = view.context; // [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    TrackView * tview = [[TrackView alloc] initWithFrame:rc context:context];
    tview.drawableDepthFormat = view.drawableDepthFormat;
    tview.backgroundColor = [UIColor clearColor];
    [view addSubview:tview];
    [view sendSubviewToBack:tview];
    [tview setupGL];
    if( starterObj )
        [tview.graph appendChild:starterObj];
    return tview;
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
            [view showSceneAndSync:400];
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
        if( view == _showingTrackView )
        {
            [view animateProp:"x"      targetVal:0 hide:false];
            [view animateProp:"y"      targetVal:0 hide:false];
            [view animateProp:"width"  targetVal:rc.size.width hide:false];
            [view animateProp:"height" targetVal:rc.size.height hide:false];
        }
        else
        {
            view.frame = rc;
            [view hideSceneAndFade];
        }
    }
}


- (void)slideToPrevView
{
    if( !_showingTrackView )
        return;
    
    NSArray * trackViews = [self getTrackViews];
    int count = [trackViews count];
    for( int i = 0; i < count-1; i++ )
    {
        if( trackViews[i] == _showingTrackView )
        {
            TrackView * next = trackViews[i+1];
            [next showAndPlay:SHOW_DIR_LEFT];
            [_showingTrackView hideAndFade:SHOW_DIR_RIGHT];
            _showingTrackView = next;
            break;
        }
    }
}

-(void)slideToNextView
{
    if( !_showingTrackView )
        return;
    
    NSArray * trackViews = [self getTrackViews];
    int count = [trackViews count];
    for( int i = 0; i < count; i++ )
    {
        if( trackViews[i] == _showingTrackView )
        {
            if( i > 0 )
            {
                TrackView * next = trackViews[i-1];
                [next showAndPlay:SHOW_DIR_RIGHT];
                [_showingTrackView hideAndFade:SHOW_DIR_LEFT];
                _showingTrackView = next;
            }
            break;
        }
    }
}

#pragma mark - Gestures

- (IBAction)onTap:(UITapGestureRecognizer *)sender {
    if( !_menuView )
        _menuView = [self makeMenuView:nil];
    
    if( !_menuView.visible )
    {
        [_menuView show];
    }
    else
    {
        [self closeAllMenus];
    }
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

@end
