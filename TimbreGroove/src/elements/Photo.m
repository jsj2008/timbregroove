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

static NSString * __str_pictureFieldName = @"picturePicker";

@implementation Photo

-(id)wireUp
{
    if( !self.textureFileName )
        self.textureFileName = @"Alex.png";
    return [super wireUp];
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
    SettingsDescriptor * sd;
    sd = [[SettingsDescriptor alloc]  initWithControlType: SC_Picture
                                               memberName: __str_pictureFieldName
                                                labelText: @"Picture"
                                                  options: @{@"target":self, @"key":@"textureFileName"}
                                             initialValue: self.textureFileName
                                                 priority: SHADER_SETTINGS];
    
    return @[sd];
    
}
@end
