//
//  TGMenuItem.h
//  TimbreGroove
//
//  Created by victor on 12/15/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Plane.h"

@protocol TGMenuItemAPI <NSObject>

@property (nonatomic,weak) NSDictionary * meta;
@property (nonatomic,weak) NSDictionary * subMenuMeta;

-(void)useIcon:(NSString *)fileName;
-(void)handleSelect;

@end

@interface TGMenuItem : Plane<TGMenuItemAPI>

@property (nonatomic,weak) NSDictionary * meta;
@property (nonatomic,weak) NSDictionary * subMenuMeta;

-(void)useIcon:(NSString *)fileName;
-(void)handleSelect;

@end
