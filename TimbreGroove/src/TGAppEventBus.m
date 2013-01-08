//
//  TGAppEventBus.m
//  TG1
//
//  Created by victor on 12/9/12.
//
//
#import "TG.h"
#import "TGAppEventBus.h"

static TGAppEventBus * _eventBus;
@interface TGAppEventBus() {
    NSMutableArray * m_observers;
}
@end

@implementation TGAppEventBus
-(TGAppEventBus *)init
{
    if( (self = [super init]))
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appIsDying:)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
    }
    
    return self;
}

-(void)appIsDying:(NSNotification *)n
{
    [self removeAllObservers];
}

+(id)listen:(NSString *)eventName klass:(Class)klass selName:(NSString *)selName
{
    return [[TGAppEventBus sharedInstance] waitForEvent:eventName klass:klass selName:selName];
}

+(void)invoke:(NSString *)eventName source:(id)source userInfo:(NSDictionary*)userInfo
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:eventName object:source userInfo:userInfo];
}


+(TGAppEventBus*) sharedInstance
{
    if( !_eventBus )
        _eventBus = [TGAppEventBus new];
    
    return _eventBus;
}

-(id)waitForEvent:(NSString *)eventName klass:(Class)klass selName:(NSString *)selName
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    __block id instance = nil;
    __block SEL method = nil;
    
    id nid = [center addObserverForName:eventName
                                 object:nil
                                  queue:nil
                             usingBlock:^(NSNotification *notification) {
                                 if( instance == nil )
                                 {
                                     /*
                                          Hey, congrats! You found it. Yup, the
                                          instantiation of the class you were looking
                                          for is buried here.
                                      */
                                     instance = [klass new];
                                     method = NSSelectorFromString(selName);
                                 }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                                 [instance performSelector:method withObject:notification];
#pragma clang diagnostic pop
                             }];
    
    if( m_observers == nil )
        m_observers = [NSMutableArray new];        
    [m_observers addObject:nid];
    return nid;
}

+(void)remove:(id)nid
{
    [[TGAppEventBus sharedInstance] removeObserver:nid];
}

-(void)removeObserver:(id)nid
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:nid];
    [m_observers removeObject:nid];
}

-(void)removeAllObservers
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    for( id nid in m_observers)
    {
        [center removeObserver:nid];
    }
    
    m_observers = nil;
}
@end
