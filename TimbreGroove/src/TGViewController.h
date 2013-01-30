//
//  TGViewController.h
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "TGTypes.h"
#import "Menu.h"
#import "Factory.h"

@interface TGViewController : GLKViewController<MenuViewDelegate,FactoryDelegate>

- (IBAction)onTap:(UITapGestureRecognizer *)sender;
- (IBAction)rightSwipe:(UISwipeGestureRecognizer *)sgr;
- (IBAction)leftSwipe:(UISwipeGestureRecognizer *)sgr;
- (IBAction)pinch:(UIPinchGestureRecognizer *)sender;

@end
