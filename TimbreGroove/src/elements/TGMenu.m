//
//  TGMenu.m
//  TimbreGroove
//
//  Created by victor on 12/15/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGMenu.h"
#import "TGMenuItem.h"

@interface TGMenu() {
    NSDictionary * _meta;
    
    TGMenu * _showingSubmenu;
    TGMenu * _subMenuOf;
}
@end

@implementation TGMenu

-(TGMenu *)init
{
    if( (self = [super init]) )
    {
        [self getMenuItems];
    }
    
    return self;
}

- (NSDictionary *)readMenuMeta:(NSString *)name
{
	NSString * menuPath = [[NSBundle mainBundle] pathForResource:@"menus"
                                                          ofType:@"plist" ];
	NSDictionary * rootMenu = [NSDictionary dictionaryWithContentsOfFile:menuPath];
	
	_meta = [rootMenu objectForKey:name];
    
    return _meta;
}

#define TG_BUTTON_EDGE 0.3f
#define TG_BUTTON_Z    -1

- (void)getMenuItems
{
    if( !_meta )
        [self readMenuMeta:@"main"];
    
    // default pos is at 0, middle of the screen (?)
    CGFloat y = 0;

    GLKVector3 scale = { TG_BUTTON_EDGE, TG_BUTTON_EDGE, TG_BUTTON_EDGE };

    for( NSString *key in _meta )
    {
        NSDictionary * menuItem = [_meta objectForKey:key];
        NSString * imageName    = [menuItem objectForKey:@"icon"];
        NSString * renderClass  = [menuItem objectForKey:@"renderClass"];
        Class klass = NSClassFromString(renderClass);
        
        TGElement <TGMenuItemAPI> * mi = [[klass alloc] init];;

        [mi useIcon:imageName];
        
        GLKVector3 position = { 0, y, TG_BUTTON_Z };
        
        mi.position     = position;
        mi.scale        = scale;
        mi.meta         = menuItem;
        mi.subMenuMeta  = menuItem[@"items"];

        [self appendChild:mi];
        
        y -= (TG_BUTTON_EDGE * 1.01f);
    }
    
}

@end
