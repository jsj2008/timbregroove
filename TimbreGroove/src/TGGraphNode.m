//
//  TGGraphNode.m
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGGraphNode.h"

@implementation TGGraphNode

-(NSArray *)children
{
    return _kids;
}

// Unfortunately this method is un-debuggable

-(bool)traverse:(SEL)selector userObj:(id)userObj
{
    for( TGGraphNode * node in _kids )
    {
        
        if ( ![node respondsToSelector:selector] )
        {
            NSLog(@"%s can’t be placed\n",
                    [NSStringFromClass([node class]) UTF8String]);
            exit(1);
        }
        
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

-(void)appendChild:(TGGraphNode *)child
{
    if( _kids == nil )
        _kids = [NSMutableArray new];
    
    [_kids addObject:child];
    child->_parent = self;
}
@end