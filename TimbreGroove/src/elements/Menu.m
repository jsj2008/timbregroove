//
//  TGMenu.m
//  TimbreGroove
//
//  Created by victor on 12/15/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Menu.h"
#import "MenuItem.h"
#import "Plane.h"
#import "TGCamera.h"
#import "TGViewController.h"

#define MENU_CAMERA 1

@interface Menu() {
    NSDictionary * _meta;
    
    TGElement * _background;
    
    Menu * _showingSubmenu;
    Menu * _subMenuOf;
}
@end


@implementation Menu

-(Menu *)init
{
    if( (self = [super init]) )
    {
#ifdef MENU_CAMERA
        TGCamera * camera = [[TGCamera alloc] init];
        
        GLKVector3 cpos = { 0, 0, MENU_CAMERA_Z };
        camera.position = cpos;
        self.camera = camera;
#endif
#if 0
        static GLKVector4 bgColor = { 0.7, 0.7, 0.7, 0.1 };
        _background = [[Plane alloc] initWithColor:bgColor];
        GLKVector3 pos = _background.position;
        pos.z = -0.1;
        _background.position = pos;
        [self appendChild:_background];
#endif
        _background = self;
        
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

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
#ifdef MENU_CAMERA
    [self.camera setPerspectiveForViewWidth:w andHeight:h];
#endif
    
    [super render:w h:h];
}

- (void)getMenuItems
{
    if( !_meta )
        [self readMenuMeta:@"main"];
    
    CGFloat y = 4.0;
    int numItems = 0;
    for( NSString *key in _meta )
    {
        NSDictionary * menuItem = [_meta objectForKey:key];
        NSString * imageName    = [menuItem objectForKey:@"icon"];
        NSString * renderClass  = [menuItem objectForKey:@"renderClass"];
        Class klass = NSClassFromString(renderClass);
        
        TGElement <MenuItemAPI> * mi = [[klass alloc] initWithIcon:imageName];

        GLKVector3 position = { 0, y, 0 };
        
        mi.position     = position;
        mi.meta         = menuItem;
        mi.subMenuMeta  = menuItem[@"items"];

        [_background appendChild:mi];
        
        y -= 2.1;
        ++numItems;
    }
    
    numItems = 0.1;
    GLKVector3 bgScale = { 1.0, numItems, 1.0 };
    _background.scale = bgScale;
    
}

@end
