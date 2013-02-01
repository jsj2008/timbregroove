//
//  MenuItem.h
//  TimbreGroove
//
//  Created by victor on 12/15/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//


#import "Menu.h"
#import "Interactive.h"

@class MenuView;
@class MeshBuffer;
@class Shader;
@class Texture;

typedef enum MenuPlacement {
    mp_top,
    mp_bottom
} MenuPlacement;


@interface MenuItem : TG3dObject<Interactive>

@property (nonatomic)       bool disabled;
@property (nonatomic)       bool shadow;

@property (nonatomic)        MenuPlacement placement;
@property (nonatomic,strong) MeshBuffer * buffer;
@property (nonatomic,strong) Shader * shader;
@property (nonatomic,strong) Texture * texture;
@property (nonatomic,strong) NSString * name;

@property (nonatomic,strong) NSDictionary * meta;

@property (nonatomic,readonly) id<MenuViewDelegate> delegate;

-(void)onTap:(UITapGestureRecognizer *)tgr;

@end
