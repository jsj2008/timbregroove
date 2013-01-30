//
//  MenuView.h
//  TimbreGroove
//
//  Created by victor on 12/18/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "View.h"
#import "Menu.h"


@interface MenuView : View
@property (nonatomic) unsigned int level;
@property (nonatomic,readonly) Menu * menu;

- (Menu *)createMenu:(NSDictionary *)meta;
- (void)show;
- (void)hide;
@end
