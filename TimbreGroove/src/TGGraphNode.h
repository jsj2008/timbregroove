//
//  TGGraphNode.h
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"

@interface TGGraphNode : NSObject {
@protected
    __weak TGGraphNode  * _parent;
    NSMutableArray      * _kids;
}

@property (nonatomic,weak)   TGGraphNode * parent;
@property (nonatomic,strong) NSArray * children;

-(void)appendChild:(TGGraphNode *)child;

-(bool)traverse:(SEL)selector userObj:(id)userObj;

@end
