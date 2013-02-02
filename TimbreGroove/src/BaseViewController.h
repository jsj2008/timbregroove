//
//  TGBaseViewController.h
//  TimbreGroove
//
//  Created by victor on 2/1/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "View.h"

@interface BaseViewController : GLKViewController

@property (nonatomic,strong) EAGLContext * context;
@property (nonatomic,readonly)  View * viewview;

-(void)startGL;
-(void)setupGL;
@end
