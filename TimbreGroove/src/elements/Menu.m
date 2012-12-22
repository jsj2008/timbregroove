//
//  TGMenu.m
//  TimbreGroove
//
//  Created by victor on 12/15/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Camera.h"
#import "Menu.h"
#import "MenuItem.h"
#import "MenuView.h"

@interface Menu() {

    Menu * _showingSubmenu;
    Menu * _subMenuOf;
}
@end


@implementation Menu

-(id)initWithMeta:(NSDictionary *)meta
{
    if( (self = [super init]) )
    {
        _meta = meta;
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

- (void)getMenuItems
{
    if( !_meta )
        [self readMenuMeta:@"main"];
    
    CGFloat y = 4.0;
    int numItems = 0;
    for( NSString *key in _meta )
    {
        NSDictionary * menuItem = _meta[key];
        NSString * imageName    = menuItem[@"icon"];
        NSString * renderClass  = menuItem[@"renderClass"];
        Class klass             = NSClassFromString(renderClass);
        
        TG3dObject <MenuItemRender> * mi = [[klass alloc] initWithIcon:imageName];

        GLKVector3 position = { 0, y, 0 };
        
        mi.position     = position;
        mi.meta         = menuItem;

        [self appendChild:mi];
        
        y -= 2.1;
        ++numItems;
    }
}

@end
