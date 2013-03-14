//
//  TGGraph.h
//  TimbreGroove
//
//  Created by victor on 12/15/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGTypes.h"
#import "TG3dObject.h"

@class ConfigGraphicElement;

@interface Graph : TG3dObject
-(void)pause;
-(void)activate;
-(id)loadFromConfig:(ConfigGraphicElement *)config andViewSize:(CGSize)viewSize;
@end
