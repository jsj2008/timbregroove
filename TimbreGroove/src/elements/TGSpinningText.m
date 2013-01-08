//
//  TGSpinningText.m
//  TG1
//
//  Created by victor on 12/9/12.
//
//

#import "TGElement.h"

@interface TGSpinningText : TGElement
@property (nonatomic,strong) NSString * text;
@end

@implementation TGSpinningText

- (void)start
{
    [super start];

    self.animate = true;
    self.text = @"Hello world";
    [self.view.camera setPosition:iv3(0, 3, 7)];
    [self genNodeWithText:self.text andFont:@"Arial" andSize:48];
}

- (void)tick:(float)dt
{
    Isgl3dNode * n = self.node;
    if(n)
        n.rotationY += 2;
}

-(void)genNodeWithText:(NSString*)text andFont:(NSString*)font andSize:(CGFloat)size
{
    Isgl3dTextureMaterial * material =
    [Isgl3dTextureMaterial materialWithText:text
                                   fontName:font
                                   fontSize:size];
    
    // Create a UV Map so that only the rendered content of the texture is shown on plane
    float uMax = material.contentSize.width / material.width;
    float vMax = material.contentSize.height / material.height;
    Isgl3dUVMap * uvMap = [Isgl3dUVMap uvMapWithUA:0 vA:0 uB:uMax vB:0 uC:0 vC:vMax];
    
    Isgl3dPlane * plane = [Isgl3dPlane meshWithGeometryAndUVMap:6 height:2 nx:2 ny:2 uvMap:uvMap];
    
    [self.view.scene clearAll];
    
    self.node = [self.view.scene createNodeWithMesh:plane
                                        andMaterial:material];
    self.node.doubleSided = YES;
    
}

@end


@interface TGSpinningTextFactory : NSObject
@end

@implementation TGSpinningTextFactory

-(void)invoke
{
    TGSpinningText * st = [[TGSpinningText alloc] init];
    [st start];
}

@end
