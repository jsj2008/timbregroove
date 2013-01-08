//
//  TGView.h
//  TG1
//
//  Created by victor on 12/8/12.
//
//

#import "Isgl3dMeshNode.h"

@interface TGView : Isgl3dView
@property (nonatomic) CGFloat x;
@property (nonatomic) CGFloat y;
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;
@property (nonatomic) NSString * tgName;

- (void)animateProp: (const char *)prop
          targetVal: (CGFloat)targetVal
               hide:(bool) hideOnComplete;

- (void)showScene;
- (void)hideScene;
@end
