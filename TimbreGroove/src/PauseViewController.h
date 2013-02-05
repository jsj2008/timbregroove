//
//  PauseViewController.h
//  TimbreGroove
//
//  Created by victor on 2/4/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PauseViewController;

@protocol PauseViewDelegate <NSObject>
-(void)PauseViewController:(PauseViewController *)pvc resume:(BOOL)ok;
@end

@interface PauseViewController : UIViewController
@property (nonatomic,weak) id<PauseViewDelegate> delegate;
- (IBAction)resume:(id)sender;

@end
