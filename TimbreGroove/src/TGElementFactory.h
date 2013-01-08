//
//  TGElementFactory.h
//  TimbreGroove
//
//  Created by victor on 12/21/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Graph;

@interface TGElementFactory : NSObject

+(id)sharedInstance;

@property (nonatomic,strong) Graph * graph;

@end
