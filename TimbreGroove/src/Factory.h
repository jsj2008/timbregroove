//
//  TGElementFactory.h
//  TimbreGroove
//
//  Created by victor on 12/21/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Menu.h" // for menuitemHandler protocol

@class Node;

@class Factory;

@protocol FactoryDelegate <NSObject>

-(void)Factory:(Factory *)factory createNode:(NSDictionary *)options;
-(void)Factory:(Factory *)factory segueTo:(NSString *)segueName;

@end

@interface Factory : NSObject <MenuItemHandler>

+(id)sharedInstance;

@property (nonatomic,weak) id<FactoryDelegate> delegate;

@end
