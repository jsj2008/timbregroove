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
        NSLog(@"created node of type: %@ (%@)", NSStringFromClass([self class]),self.description);
    }
    return self;
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
    for( Node * node in _kids )
    {
#if DEBUG
        if ( ![node respondsToSelector:selector] )
        {
            NSLog(@"%@ can’t be placed\n", node);
            exit(1);
        }
#endif
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [node performSelector:selector withObject:userObj];
#pragma clang diagnostic pop
        
        if( ![node traverse:selector userObj:userObj] )
        {
            return false;
        }
        
    }
    
    return true;
}


-(void)appendChild:(Node *)child
{
    if( _kids == nil )
        _kids = [NSMutableArray new];
    
    [_kids addObject:child];
    child->_parent = self;
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
