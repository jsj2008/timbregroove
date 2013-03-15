//
//  TGGraph.m
//  TimbreGroove
//
//  Created by victor on 12/15/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Graph.h"
#import "Camera.h"
#import "Global.h"
#import "Config.h"
#import "GraphView+Touches.h"

#import "Parameter.h"
#import "TriggerMap.h"
#import "Scene.h"
#import "Names.h"

typedef void (^RecurseBlock)(TG3dObject *);

@interface GraphTriggers : NSObject {
    @public
    FloatParamBlock _timerTrigger;
    FloatParamBlock _updateTrigger;
}
@end
@implementation GraphTriggers

-(void)triggersChanged:(Scene *)scene
{
    if( scene )
    {
        _timerTrigger  = [scene.triggers getFloatTrigger:kTriggerTimer];
        _updateTrigger = [scene.triggers getFloatTrigger:kTriggerUpdate];
    }
    else
    {
        _timerTrigger = nil;
        _updateTrigger = nil;
    }
}

@end
@interface Graph() {
    // as of this writing the majority of graphs (all?)
    // only have one top level node. Keep a pointer
    // so we don't do any unnecessary ARC calls into _kids[]
    // during update and render
     __weak  TG3dObject * _single;
    
    NSTimeInterval _runningTime;
    bool _isPaused;
    NSMutableArray * _triggerStack;
    GraphTriggers *  _currentTriggers;
}

@property (nonatomic,weak) TG3dObject * modal;
@end
@implementation Graph

-(id)init
{
    self = [super init];
    if( self )
    {
        self.camera = [Camera new];
    }
    
    return self;
}

-(void)dealloc
{
    self.view = nil;
    _single = nil;
    NSLog(@"Graph object gone");
}

-(void)traverseWithObj:(id)param selector:(SEL)selector
{
    static RecurseBlock generalIter;

    generalIter = ^(TG3dObject * obj)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if( param )
            [obj performSelector:selector withObject:param];
        else
            [obj performSelector:selector];
#pragma clang diagnostic pop
        [obj->_kids each:generalIter];
    };

    if( _modal )
        generalIter(_modal);
    else if( _single )
        generalIter(_single);
    else
        generalIter(self);
    
    generalIter = nil;
}

-(void)pushTriggers
{
    _currentTriggers = [GraphTriggers new];
    if( !_triggerStack )
        _triggerStack = [NSMutableArray new];
    [_triggerStack addObject:_currentTriggers];
}

-(void)popTriggers
{
    [_currentTriggers triggersChanged:nil];
    [_triggerStack removeLastObject];
    _currentTriggers = [_triggerStack lastObject];
}

-(id)loadFromConfig:(ConfigGraphicElement *)config andViewSize:(CGSize)viewSize modal:(bool)modal
{
    Class klass = NSClassFromString(config.instanceClass);
    TG3dObject * node = [[klass alloc] init];
    [self appendChild:node];
    NSDictionary * userData = config.customProperties;
    if( userData )
        [node setValuesForKeysWithDictionary:userData];
    [node wireUpWithViewSize:viewSize];
    if( modal )
        self.modal = node;
    return node;
}

-(void)setModal:(TG3dObject *)modal
{
    GraphView * view = [self hasView];
    
    if( _modal )
    {
        if( view )
           [view popTriggers];
        
        [self popTriggers];
    }
    
    bool either = !!_modal || !!modal;
    
    _modal = modal;
    
    if( view )
    {
        if( modal )
        {
            [view pushTriggers];
            [self pushTriggers];
        }
        
        if( either ) 
            [view graphChanged];
    }
    else if( modal )
    {
        [self pushTriggers];
    }
}

-(void)setView:(GraphView *)view
{
    [super setView:view];
    if( _modal )
    {
        [view pushTriggers];
        [view graphChanged];
    }
}

-(void)appendChild:(Node *)child
{    
    _single = _kids == nil ? (TG3dObject*)child : nil;
    [super appendChild:child];
}

-(void)removeChild:(Node *)child
{
    [super removeChild:child];
    if( [_kids count] == 1 )
        _single = _kids[0];
    if( child == _modal )
    {
        self.modal = nil;
    }
    else
    {
        GraphView * view = [self hasView];
        if( view )
            [view graphChanged];
    }
}

-(void)activate
{
    _isPaused = false;
}

-(void)pause
{
    _isPaused = true;
}

-(void)update:(NSTimeInterval)dt
{
    if( _isPaused )
        return;
    
    if( _currentTriggers->_timerTrigger )
    {
        _runningTime += dt;
        _currentTriggers->_timerTrigger(_runningTime);
    }
    
    if( _currentTriggers->_updateTrigger )
        _currentTriggers->_updateTrigger(dt);

    static RecurseBlock updateBlock;
    
    if( !updateBlock )
    {
        updateBlock = ^(TG3dObject *n)
        {
            n->_totalTime += dt;
            n->_timer += dt;
            [n update:dt];
            [n->_kids each:updateBlock];
        };
    }
    
    if( _modal )
        updateBlock(_modal);
    else if( _single )
        updateBlock(_single);
    else
        updateBlock(self);
    
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    if( _isPaused )
        return;
    
    static RecurseBlock renderBlock;
    
    if( !renderBlock )
    {
        renderBlock = ^(TG3dObject *n)
        {
            [n render:w h:h];
            [n->_kids each:renderBlock];
        };
    }
    
    if( _modal )
        renderBlock(_modal);
    else if( _single )
        renderBlock(_single);
    else
        renderBlock(self);
}

- (void)getSettings:(NSMutableArray *)settings
{
    [self traverseWithObj:settings selector:@selector(getSettings:)];
}

-(id)settingsChanged
{
    [self traverseWithObj:nil selector:@selector(settingsChanged)];
    return nil;
}

-(void)getParameters:(NSMutableDictionary *)putHere;
{
    [self traverseWithObj:putHere selector:@selector(getParameters:)];
}

-(void)triggersChanged:(Scene *)scene
{
    if( !_currentTriggers )
        [self pushTriggers];
    
    [_currentTriggers triggersChanged:scene];
    
    [self traverseWithObj:scene selector:@selector(triggersChanged:)];
}

- (void)getTriggerMap:(NSMutableArray *)putHere
{
    [self traverseWithObj:putHere selector:@selector(getTriggerMap:)];
}

@end
