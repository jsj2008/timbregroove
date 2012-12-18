//
//  MenuItem.h
//  TimbreGroove
//
//  Created by victor on 12/15/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Plane.h"

@protocol MenuItemAPI <NSObject>

@property (nonatomic,weak) NSDictionary * meta;
@property (nonatomic,weak) NSDictionary * subMenuMeta;

-(id)initWithIcon:(NSString *)fileName;
-(void)handleSelect;

@end

@interface MenuItem : Plane<MenuItemAPI>

@property (nonatomic,weak) NSDictionary * meta;
@property (nonatomic,weak) NSDictionary * subMenuMeta;

-(id)initWithIcon:(NSString *)fileName;
-(void)handleSelect;

@end
