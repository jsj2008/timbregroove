//
//  TGMenuItem.h
//  TG1
//
//  Created by victor on 12/8/12.
//
//

#import "Isgl3dMeshNode.h"
#import "TGMenu.h"

#define TG_BUTTON_EDGE     0.5f
#define TG_BUTTON_Z        -4
#define TG_BUTTON_CAMERA_Z 4

@interface TGMenuItem : Isgl3dMeshNode

@property (nonatomic,strong) NSDictionary * meta;
@property (nonatomic,strong) NSDictionary * subMenuMeta;
@property (nonatomic,strong) TGMenu * subMenu;
@property (nonatomic,strong) id target;

+(TGMenuItem *)    imageName: (NSString *)imageName
                      target:(id)target
                    selector:(SEL)selector;
@end
