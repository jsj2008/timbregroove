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

-(void)Factory:(Factory *)factory onNodeCreated:(Node*)node;

@end

@interface Factory : NSObject <MenuItemHandler>

+(id)sharedInstance;

@property (nonatomic,weak) id<FactoryDelegate> delegate;

@end
