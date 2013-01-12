//
//  Photo.m
//  TimbreGroove
//
//  Created by victor on 12/21/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Photo.h"
#import "SettingsVC.h"

static NSString * __str_pictureFieldName = @"picturePicker";

@implementation Photo

-(id)wireUp
{
    if( !self.textureFileName )
        self.textureFileName = @"Alex.png";
    return [super wireUp];
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
