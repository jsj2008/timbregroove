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
#import "__GenericShader.h"

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

    if( !klassName )
    {
#if DEBUG
        NSLog(@"Missing 'instanceClass' in menus.plist for this menu item");
        exit(1);
#endif
        return;
    }
    
    Class klass = NSClassFromString(klassName);
    Node * node = [klass new];
    [_delegate Factory:self onNodeCreated:node];
}

@end
