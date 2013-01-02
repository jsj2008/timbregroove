//
//  TGElementFactory.h
//  TimbreGroove
//
//  Created by victor on 12/21/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Menu.h"

@class Factory;

@protocol FactoryDelegate <NSObject>

-(NSDictionary *)Factory:(Factory *)factory willCreateNode:(NSString *)name options:(NSDictionary *)options;
-(void)Factory:(Factory *)factory onNodeCreated:(Node*)node;
-(void)Factory:(Factory *)factory segueTo:(NSString *)segueName;

@end

@interface Factory : NSObject <MenuItemHandler>

+(id)sharedInstance;

@property (nonatomic,weak) id<FactoryDelegate> delegate;

@end
