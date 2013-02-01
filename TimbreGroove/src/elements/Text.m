//
//  Text.m
//  TimbreGroove
//
//  Created by victor on 12/21/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Texture.h"
#import "Camera.h"
#import "SettingsVC.h"
#import "SimpleImage.h"

@interface Text : SimpleImage

@property (nonatomic,strong) NSString * text;
@end

NSString * const __str_textFieldName = @"textTexture";

@interface Text() {
    NSTimeInterval _time;
}
@end

@implementation Text

-(id)wireUp
{
    if( !_text )
        _text = @"Ass Over Teakettle";
    return [super wireUp];
}

-(void)createTexture
{
    self.texture = [[Texture alloc] initWithString:_text];
}

-(void)update:(NSTimeInterval)dt
{
    _time += (dt*15);
    GLKVector3 rot = { 0, GLKMathDegreesToRadians(_time), 0 };
    self.rotation = rot;
}

-(void)setText:(NSString *)text
{
    _text = text;
    [self createTexture];
    [self getTextureLocations];
}

-(NSArray *)getSettings
{
    SettingsDescriptor * sd;
    sd = [[SettingsDescriptor alloc]  initWithControlType: SC_Text
                                               memberName: __str_textFieldName
                                                labelText: @"Text"
                                                  options: @{@"target":self, @"key":@"text"}
                                             initialValue: _text
                                                 priority: SHADER_SETTINGS];
    
    return @[sd];
    
}

@end
