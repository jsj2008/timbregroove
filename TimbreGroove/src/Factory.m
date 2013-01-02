//
//  TGElementFactory.m
//  TimbreGroove
//
//  Created by victor on 12/21/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Factory.h"
#import "Graph.h"
#import "Photo.h"
#import "GenericShader.h"

static Factory * __f;

@implementation Factory

+(id)sharedInstance
{
    if( !__f )
        __f = [Factory new];
    return __f;
}

-(id)init
{
    if( (self = [super init]) )
    {
        if( __f )
            _delegate = __f->_delegate;
    }
    return self;
}

-(void)handleSelect:(id<MenuItemRender>) menuItem
{
    NSDictionary * meta = menuItem.meta;
    NSDictionary * ud   = meta[@"userData"];
    
    if( !ud )
    {
#if DEBUG
        NSLog(@"Missing userData in menus.plist for this menu item");
        exit(1);
#endif
        return;
    }
    
    NSString * klassName = ud[@"instanceClass"];

    if( klassName )
    {
        NSDictionary * options = [_delegate Factory:self willCreateNode:klassName options:ud];
        Class klass = NSClassFromString(klassName);
        Node * node;
        if( options )
            node = [[klass alloc] initWithObject:options];
        else
            node = [klass new];
        [_delegate Factory:self onNodeCreated:node];
    }
    else
    {
        NSString * segue = ud[@"segueTo"];
        
        [_delegate Factory:self segueTo:segue];
        
    }
}

@end
