//
//  MenuItem.h
//  TimbreGroove
//
//  Created by victor on 12/15/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "SimpleImage.h"
#import "Menu.h"
#import "Interactive.h"

@class MenuView;
@class MeshBuffer;

@interface MenuItem : SimpleImage<MenuItemRender, Interactive>

@property (nonatomic,strong) MeshBuffer * buffer;
@property (nonatomic,strong) NSDictionary * meta;

-(void)onTap:(UITapGestureRecognizer *)tgr;

@end
