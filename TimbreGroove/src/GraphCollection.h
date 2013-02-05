//
//  GraphCollection.h
//  TimbreGroove
//
//  Created by victor on 2/3/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GraphCollection : NSObject

@property (nonatomic,readonly) unsigned int count;

-(id)createGraphBasedOnNodeType:(NSDictionary *)params withViewSize:(CGSize)viewSize;
-(id)graphAtIndex:(unsigned int)i;
-(void)removeGraphAtIndex:(unsigned int)i;
@end
