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

-(id)wireUp
{
    [super wireUp];
    [self getMenuItems];
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
    
    CGFloat y = 6.0;
    int numItems = 0;
    for( NSString *key in _meta )
    {
        NSDictionary * menuItem = _meta[key];
        NSString * imageName    = menuItem[@"icon"];
        NSString * renderClass  = menuItem[@"renderClass"];
        Class klass             = NSClassFromString(renderClass);
        
        MenuItem * mi = [[klass alloc] init];

        GLKVector3 position = { 0, y, 0 };
        
        mi.textureFileName = imageName;
        mi.position     = position;
        mi.meta         = menuItem;

        [mi wireUp];
        [self appendChild:mi];
        
        y -= 2.1;
        ++numItems;
    }
}

@end
