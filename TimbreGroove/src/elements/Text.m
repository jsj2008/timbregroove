//
//  Text.m
//  TimbreGroove
//
//  Created by victor on 12/21/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
#import "Text.h"
#import "Material.h"
#import "Camera.h"
#import "SettingsVC.h"

NSString * const __str_textFieldName = @"textTexture";

@implementation Text

-(id)wireUp
{
    if( !_text )
        _text = @"Ass Over Teakettle";
    return [super wireUp];
}

-(void)createShader
{
    if( !self.texture )
        self.texture = [[Texture alloc] initWithString:_text];
    [super createShader];
}

-(void)setText:(NSString *)text
{
    _text = text;
}

- (void)getSettings:(NSMutableArray *)putHere
{
    SettingsDescriptor * sd;
    sd = [[SettingsDescriptor alloc]  initWithControlType: SC_Text
                                               memberName: __str_textFieldName
                                                labelText: @"Text"
                                                  options: @{@"target":self, @"key":@"text"}
                                             initialValue: _text
                                                 priority: SHADER_SETTINGS];
    
    [putHere addObject:sd];
    
}

@end
