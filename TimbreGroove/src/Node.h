//
//  TGGraphNode.h
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"

@interface Node : NSObject {
@protected
    __weak Node  * _parent;
    NSMutableArray      * _kids;
}

@property (nonatomic,weak)   Node * parent;
@property (nonatomic,strong) NSArray * children;

-(void)appendChild:(Node *)child;

-(bool)traverse:(SEL)selector userObj:(id)userObj;

@end
