//
//  Interactive.h
//  TimbreGroove
//
//  Created by victor on 12/21/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol Interactive <NSObject>

@optional
-(void)onTap:(UITapGestureRecognizer *)tgr;

@end
