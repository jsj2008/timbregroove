//
//  TGMenu.h
//  TG1
//
//  Created by victor on 12/8/12.
//
//

#import "TGView.h"

#define TG_MENU_WIDTH 60

#define TG_MAIN_MENU_NAME @"main" // N.B. Must match name in menus.plist

@interface TGMenu : TGView

@property (nonatomic) unsigned int level;

- (void)showMenu;
- (void)hideMenu;
- (void)toggleShowHide;
- (id) initWithName: (NSString *)name;
- (id) initWithMeta: (NSDictionary *)meta;

@end
