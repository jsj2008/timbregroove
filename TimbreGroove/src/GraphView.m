//
//  View.m
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "GraphView.h"
#import "Global.h"
#import "Camera.h"

@interface GraphView () {
    bool    _panTracking;
    CGPoint _panStart;
    CGPoint _panLast;
    CGPoint _panDirs;
    
    NSMutableArray * _watchingGlobals;
    int _phonyContext;
}
@end

@implementation GraphView

- (id)initWithFrame:(CGRect)frame context:(EAGLContext *)context;
{
    self = [super initWithFrame:frame context:context];
    if (self) {
        [self wireUp];
    }
    return self;
}

-(void)watchForGlobals:(id)target lookup:(NSDictionary *)lookups
{
    NSMutableDictionary * graphDict = _graph.globalNotifees;
    if( !graphDict )
    {
        graphDict = [NSMutableDictionary new];
        _graph.globalNotifees = graphDict;
    }
    for (NSString * propName in lookups )
    {
        NSMutableArray * notifieesForProp = graphDict[propName];
        if( !notifieesForProp )
        {
            notifieesForProp = [NSMutableArray new];
            graphDict[propName] = notifieesForProp;
        }
        [notifieesForProp addObject:@[target,lookups[propName]]];
        if( [_watchingGlobals indexOfObject:propName] == NSNotFound )
        {
            [_watchingGlobals addObject:propName];
            [[Global sharedInstance] addObserver:self
                                      forKeyPath:propName
                                         options:NSKeyValueObservingOptionNew
                                         context:&_phonyContext];
        }
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    NSMutableDictionary * graphDict = _graph.globalNotifees;
    if( graphDict )
    {
        NSArray * notifieesForProp = graphDict[keyPath];
        
        // this can be null when another graph (no
        // longer in view) requested this property
        if( notifieesForProp )
        {
            for( NSArray * targetInfo in notifieesForProp )
            {
                id target = targetInfo[0];
                SEL sel = NSSelectorFromString(targetInfo[1]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [target performSelector:sel];
#pragma clang diagnostic pop
            }
        }
    }
    
}
- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self wireUp];
    }
    return self;
}

-(void)wireUp
{
    _backcolor = (GLKVector4){0, 0, 0, 1};

    self.opaque = YES;
    
    _watchingGlobals = [NSMutableArray new];
    
    _recordGesture = [[RecordGesture alloc] initWithTarget:self action:@selector(record:)];
    [self addGestureRecognizer:_recordGesture];
    
    _tapRecordGesture = [[TapRecordGesture alloc] initWithTarget:self action:@selector(tapRecord:)];
    [self addGestureRecognizer:_tapRecordGesture];
    
    UIPanGestureRecognizer * pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panning:)];
    [self addGestureRecognizer:pgr];
}

-(void)panning:(UIPanGestureRecognizer *)pgr
{
    if( pgr.state == UIGestureRecognizerStateChanged )
    {
        CGSize sz       = self.frame.size;
        CGPoint pt      = [pgr locationInView:self];
        
        if( _panTracking )
        {
            // We notice a change in direction here:
            float currXdir = pt.x - _panLast.x < 0.0 ? -1 : 1;
            float currYdir = pt.y - _panLast.y < 0.0 ? -1 : 1;
            if( (currXdir != _panDirs.x) || (currYdir != _panDirs.y) )
            {
                _panStart = _panLast;
                _panDirs = (CGPoint){ currXdir, currYdir };
            }
        }
        else
        {
            _panStart = pt;
            _panLast = pt;
            _panDirs = (CGPoint){ 1, 1 };
            _panTracking = true;
        }
        Global * global = [Global sharedInstance];

        global.panXBy = (pt.x - _panStart.x) / sz.width;
        global.panYBy = -(pt.y - _panStart.y) / sz.height;

        _panLast = pt;
    }
    else
    {
        _panTracking = false;
    }
}

-(void)record:(RecordGesture *)upg
{
}

-(void)tapRecord:(TapRecordGesture *)trg
{
    
}

- (void)update:(NSTimeInterval)dt mixerUpdate:(MixerUpdate *)mixerUpdate
{
    [_graph update:dt mixerUpdate:mixerUpdate];
}

-(void)setGraph:(Graph *)graph
{
    if( _graph )
        [_graph traverse:@selector(didDetachFromView:) userObj:self];
    _graph = graph;
    _graph.view = self;
    [_graph traverse:@selector(didAttachToView:) userObj:self];
}

-(void)render // drawRect:(CGRect)rect
{
    NSUInteger w = self.drawableWidth;
    NSUInteger h = self.drawableHeight;
    [_graph.camera setPerspectiveForViewWidth:w andHeight:h];
    
    glClearColor(_backcolor.r,_backcolor.g,_backcolor.b,_backcolor.a);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    [_graph render:w h:h];
}

-(NSArray *)getSettings
{
    return [_graph getSettings];
}

-(void)commitSettings
{
    [_graph settingsChanged];
}

@end
