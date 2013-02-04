//
//  MenuView.h
//  TimbreGroove
//
//  Created by victor on 12/18/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "GraphView.h"
#import "Menu.h"


@interface MenuView : GraphView
@property (nonatomic) unsigned int level;
@property (nonatomic,readonly) Menu * menu;

- (Menu *)createMenu:(NSDictionary *)meta;
@end
