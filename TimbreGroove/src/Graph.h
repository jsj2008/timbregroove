//
//  TGGraph.h
//  TimbreGroove
//
//  Created by victor on 12/15/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGTypes.h"
#import "Node3d.h"

@class ConfigGraphicElement;

@interface Graph : Node3d
-(void)pause;
-(void)activate;
-(id)loadFromConfig:(ConfigGraphicElement *)config andViewSize:(CGSize)viewSize modal:(bool)modal;
@property (nonatomic,strong) NSDictionary * viewBasedParameters;
@end
