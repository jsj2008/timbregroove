//
//  TGMenu.h
//  TimbreGroove
//
//  Created by victor on 12/15/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TG3dObject.h"

#define MENU_VIEW_WIDTH 70 // pixels
#define MENU_ITEM_SIZE  60 // pixels is that big enough?

@class Menu;
@class MenuView;
@class MenuItem;
@class MeshBuffer;

@protocol MenuViewDelegate <NSObject> // TGViewController

- (MenuView *)Menu:(Menu*)menu makeMenuView:(NSDictionary *)meta;
- (bool)      Menu:(Menu*)menu shouldEnable:(MenuItem *)mi;
- (int)       Menu:(Menu*)menu playMode:(MenuItem *)mi;

@end

@protocol MenuItemHandler <NSObject> // Factory

-(void)handleSelect:(NSDictionary *) menuItemMeta;

@end

@interface Menu : TG3dObject

@property (nonatomic,weak) NSDictionary * meta;

@property (nonatomic,readonly) MenuView *        menuView;
@property (nonatomic,strong) id<MenuViewDelegate> delegate;

@property (nonatomic,strong) MeshBuffer * buffer;

-(void)willBecomeVisible;

@end
