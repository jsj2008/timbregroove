//
//  TGGraphNode.m
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Node.h"

@implementation Node

#if DEBUG
-(id)init
{
    if( (self = [super init]))
    {
        TGLog(LLObjLifetime, @"%@ created",self);
    }
    return self;
}

-(void)dealloc
{
    TGLog(LLObjLifetime, @"%@ released", self);
}
#endif

-(NSArray *)children
{
    return _kids;
}

-(id)firstChild
{
    return _kids[0];
}

-(void)cleanChildren
{
    _kids = nil;
}

// Unfortunately this method is un-debuggable

-(bool)traverse:(SEL)selector userObj:(id)userObj
{
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:selector withObject:userObj];
    
    for( Node * node in _kids )
    {
        [node performSelector:selector withObject:userObj];
        
        if( ![node traverse:selector userObj:userObj] )
        {
            return false;
        }
    }
#pragma clang diagnostic pop
    
    return true;
}


-(void)appendChild:(Node *)child
{
    if( _kids == nil )
        _kids = [NSMutableArray new];
    
    [_kids addObject:child];
    child->_parent = self;
}

-(void)removeChild:(Node *)child
{
    [_kids removeObject:child];
}

-(void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    if( !_dynamicVars )
        _dynamicVars = [NSMutableDictionary new];
    _dynamicVars[key] = value;
    
}

-(id)valueForUndefinedKey:(NSString *)key
{
    return _dynamicVars[key];
}
@end
