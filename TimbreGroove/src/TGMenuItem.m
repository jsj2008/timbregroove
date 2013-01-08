//
//  TGMenuItem.m
//  TG1
//
//  Created by victor on 12/8/12.
//
//

#import "isgl3d.h"
#import "TGMenuItem.h"

@implementation TGMenuItem

+(TGMenuItem *)    imageName: (NSString *)imageName
                      target:(id)target
                    selector:(SEL)selector
{
    return [[TGMenuItem alloc] initWithImage:imageName target:target selector:selector];
}

-(TGMenuItem *)initWithImage: (NSString *)imageName
                 target:(id)target
               selector:(SEL)selector
{
    Isgl3dTextureMaterial * bMat = [Isgl3dTextureMaterial materialWithTextureFile:imageName
                                                                        shininess:0.9
                                                                        precision:Isgl3dTexturePrecisionMedium
                                                                          repeatX:NO
                                                                          repeatY:NO];
    
    Isgl3dPlane *plane = [[Isgl3dPlane alloc] initWithGeometry:TG_BUTTON_EDGE
                                                        height:TG_BUTTON_EDGE
                                                            nx:2
                                                            ny:2];
    
    if( (self = [super initWithMesh:plane andMaterial:bMat]) )
    {
        self.interactive = YES;
        [self addEvent3DListener:target method:selector forEventType:TOUCH_EVENT];        
    }
    
    return self;
    
}

@end
