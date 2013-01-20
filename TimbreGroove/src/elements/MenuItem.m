//
//  MenuItem.m
//  TimbreGroove
//
//  Created by victor on 12/15/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Menu.h"
#import "MenuItem.h"
#import "MenuView.h"

@interface MenuItem() {
    Menu * _subMenu;
    bool _testedForSubMenu;
}
@end

@implementation MenuItem

-(id)init
{
    return [super init];
}

#if DEBUG
-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    [super render:w h:h];
}
#endif

-(void)createBuffer
{
    [self addBuffer:_buffer];
    _buffer = nil;
}

-(void)onTap:(UITapGestureRecognizer *)tgr;
{
    if( !_testedForSubMenu )
    {
        NSDictionary * subMenuMeta = _meta[@"items"];
        
        if( subMenuMeta )
        {
            Menu * owner = (Menu *)self.parent;
            id<MenuViewMaker> maker = owner.viewMaker;
            MenuView * view = [maker makeMenuView:subMenuMeta];
            view.level = owner.menuView.level + 1;
            _subMenu = view.menu;
        }
        
        _testedForSubMenu = true;
    }
    
    if( _subMenu )
    {
        [_subMenu.menuView show];
    }
    else
    {
        NSString * handlerClass = _meta[@"handler"];
        if( handlerClass )
        {
            Class klass = NSClassFromString(handlerClass);
            id<MenuItemHandler> mh = [[klass alloc] init];
            [mh handleSelect:_meta];
        }
    }
}

@end
