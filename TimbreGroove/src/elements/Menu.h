//
//  TGMenu.h
//  TimbreGroove
//
//  Created by victor on 12/15/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TG3dObject.h"

#define MENU_CAMERA_Z    -20.0

@class Menu;
@class MenuView;

@protocol MenuViewMaker <NSObject>

- (MenuView *)makeMenuView:(NSDictionary *)meta;

@end

@protocol MenuItemRender <NSObject>

@property (nonatomic,strong) NSDictionary * meta;

-(id)initWithIcon:(NSString *)fileName;
@end

@protocol MenuItemHandler <NSObject>

-(void)handleSelect:(NSDictionary *) menuItemMeta;

@end

@interface Menu : TG3dObject

@property (nonatomic,weak) NSDictionary * meta;

@property (nonatomic,strong) MenuView *        menuView;
@property (nonatomic,strong) id<MenuViewMaker> viewMaker;

-(id)initWithMeta:(NSDictionary *)meta;

@end
