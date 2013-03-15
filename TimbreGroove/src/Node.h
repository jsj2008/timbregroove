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
    NSMutableDictionary * _dynamicVars;
}

// weak to avoid circular locks on releasing everybody
// i.e. this will be set to null when no one else has
// a strong reference pointer to the parent
@property (nonatomic,weak)   Node * parent;
@property (nonatomic,strong) NSArray * children;
@property (nonatomic,readonly) id firstChild;

-(void)appendChild:(Node *)child;
-(void)removeChild:(Node *)child;
-(void)cleanChildren;

-(bool)traverse:(SEL)selector userObj:(id)userObj;

@end
