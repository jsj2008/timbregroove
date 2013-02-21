//
//  Photo.m
//  TimbreGroove
//
//  Created by victor on 12/21/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Photo.h"
#import "SettingsVC.h"
#import "Texture.h"
#import "GridPlane.h"
#import "Mixer.h"

static NSString * __str_pictureFieldName = @"picturePicker";

@interface Photo () {
}
@end

@implementation Photo

-(id)wireUp
{
    if( !self.textureFileName )
        self.textureFileName = @"Alex.png";
    [super wireUp];
    self.distortionFactor = 1.0;
    return self;
}

-(void)createBuffer
{
    GridPlane * gp = [GridPlane gridWithWidth:2.0
                                     andGrids:20
                          andIndicesIntoNames:@[@(gv_pos),@(gv_uv)]
                                     andDoUVs:true
                                 andDoNormals:false];
    [self addBuffer:gp];
}


-(void)setTexture:(Texture *)texture
{
    [super setTexture:texture];
    if( self.texture )
    {
        CGSize sz = self.texture.orgSize;
        GLKVector3 scale = { 1, 1, 1 };
        if( sz.height > sz.width )
        {
            scale.y = sz.height / sz.width;
        }
        else if ( sz.width > sz.height )
        {
            scale.x = sz.width / sz.height;
        }
        self.scale = scale;
    }
}

-(NSArray *)getSettings
{
    NSMutableArray * arr = [[NSMutableArray alloc] initWithArray:[super getSettings]];
    SettingsDescriptor * sd;
    sd = [[SettingsDescriptor alloc]  initWithControlType: SC_Picture
                                               memberName: __str_pictureFieldName
                                                labelText: @"Picture"
                                                  options: @{@"target":self, @"key":@"textureFileName"}
                                             initialValue: self.textureFileName
                                                 priority: SHADER_SETTINGS];
    
    [arr addObject:sd];
    return arr;
    
}
@end
