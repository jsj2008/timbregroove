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
#import "Texture.h"
#import "Shader.h"
#import "MeshBuffer.h"

@interface MenuItem() {
    Menu * _subMenu;
    bool _testedForSubMenu;
}
@end

@implementation MenuItem

// render actually happens in parent (Menu*) render:h

-(void)update:(NSTimeInterval)dt
{
    Menu * owner = (Menu *)self.parent;
    self.disabled = ![owner.delegate Menu:owner shouldEnable:self];
}

-(void)onTap:(UITapGestureRecognizer *)tgr;
{
    if( !_testedForSubMenu )
    {
        NSDictionary * subMenuMeta = _meta[@"items"];
        
        if( subMenuMeta )
        {
            Menu * owner = (Menu *)self.parent;
            MenuView * view = [owner.delegate Menu:owner makeMenuView:subMenuMeta];
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

// capture hack
-(void)renderToCaptureAtBufferLocation:(GLint)location
{
    if( !self.disabled )
    {
        Menu * menu = (Menu *)(self.parent);
        MeshBuffer * buffer = menu.buffer;
        [buffer bindToTempLocation:location];
        [buffer draw];
    }
}

-(GLKMatrix4)calcPVM
{
    return self.modelView;
}


@end
