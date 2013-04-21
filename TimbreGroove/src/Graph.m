//
//  TGGraph.m
//  TimbreGroove
//
//  Created by victor on 12/15/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Graph.h"
#import "Global.h"
#import "Config.h"
#import "GraphView.h"

#import "Parameter.h"
#import "TriggerMap.h"
#import "Scene.h"
#import "Names.h"

#import "PainterCamera.h"

typedef void (^RecurseBlock)(TG3dObject *);

@interface GraphTriggers : NSObject {
    @public
    FloatParamBlock _timerTrigger;
    FloatParamBlock _updateTrigger;
    FloatParamBlock _tickTrigger;
}
@end
@implementation GraphTriggers

-(void)triggersChanged:(Scene *)scene
{
    if( scene )
    {
        _timerTrigger  = [scene.triggers getFloatTrigger:kTriggerTimer];
        _updateTrigger = [scene.triggers getFloatTrigger:kTriggerUpdate];
        _tickTrigger   = [scene.triggers getFloatTrigger:kTriggerTick];
    }
    else
    {
        _timerTrigger = nil;
        _updateTrigger = nil;
        _tickTrigger = nil;
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
-(void)traverseWithObj:(id)param selector:(SEL)selector
{
    static RecurseBlock generalIter;

    generalIter = ^(TG3dObject * obj)
    {
        if( obj != self )
            [obj performSelector:selector withObject:param];
        if( obj->_kids )
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
#pragma clang diagnostic pop

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
    self.camera = [[PainterCamera alloc] init];
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
    
   static RecurseBlock wipeTriggers;
    
    wipeTriggers = ^(TG3dObject * obj)
    {
        [obj triggersChanged:nil];
        if( obj->_kids )
            [obj->_kids each:wipeTriggers];
    };
    
    wipeTriggers((TG3dObject *)child);
    wipeTriggers = nil;
    child = nil;
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

    if( _currentTriggers->_tickTrigger )
        _currentTriggers->_updateTrigger(dt / 1000.0);
    
    static RecurseBlock updateBlock;
    
    updateBlock = ^(TG3dObject *n)
    {
        if( n != self )
        {
            n->_totalTime += dt;
            n->_timer += dt;
            [n update:dt];
        }
        if( n->_kids )
            [n->_kids each:updateBlock];
    };
    
    if( _modal )
        updateBlock(_modal);
    else if( _single )
        updateBlock(_single);
    else
        updateBlock(self);
    
    updateBlock = nil;
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    if( _isPaused )
        return;
    
    static RecurseBlock renderBlock;
    
    renderBlock = ^(TG3dObject *n)
    {
        if( n != self )
            [n render:w h:h];
        if( n->_kids )
            [n->_kids each:renderBlock];
    };

    if( _modal )
        renderBlock(_modal);
    else if( _single )
        renderBlock(_single);
    else
        renderBlock(self);
    
    renderBlock = nil;
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
    NSMutableDictionary * graphParameters = [NSMutableDictionary new];
    
    [self traverseWithObj:graphParameters selector:@selector(getParameters:)];
    
    _viewBasedParameters = [graphParameters mapReduce:^id(NSString *name, Parameter *parameter) {
        if( parameter.targetObject )
            return parameter;
        return nil;
    }];
    
    [putHere addEntriesFromDictionary:graphParameters];
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
