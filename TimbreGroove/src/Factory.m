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
	@synchronized (self) {
        if( !__f )
            __f = [Factory new];
    }
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

-(void)handleSelect:(NSDictionary *) meta
{
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
        [_delegate Factory:self createNode:ud];
        return;
    }

    NSString * segue = ud[@"segueTo"];

    if( segue )
    {
        [_delegate Factory:self segueTo:segue];
        return;
    }
    
    NSString * command = ud[@"command"];
    
    if( command )
    {
        if( [command isEqualToString:@"deleteNode"] )
        {
            [_delegate Factory:self deleteNode:ud];
        }
        else if( [command isEqualToString:@"pauseToggle"] )
        {
            [_delegate Factory:self pauseToggle:ud];
        }
    }
}

@end
