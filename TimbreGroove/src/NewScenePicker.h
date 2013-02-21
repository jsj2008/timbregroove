//
//  NewScenePicker.h
//  TimbreGroove
//
//  Created by victor on 2/3/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NewSceneViewController.h"

@class NewScenePicker;
@class NewSceneViewController;
@class ConfigScene;

@protocol NewSceneDelegate <NSObject>

-(void)NewScene:(NewSceneViewController *)picker selection:(ConfigScene *)scene;

@end

@interface NewScenePicker : UICollectionViewController <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic,weak) id<NewSceneDelegate> delegate;
@end
