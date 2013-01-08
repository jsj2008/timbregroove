//
//  ImageBakerView.m
//  TimbreGroove
//
//  Created by victor on 1/6/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "ImageBakerView.h"
#import "SettingsVC.h"

static const char * __bakerShakerModes[] = {
    "BLUE_DOWN", "SOLARIZE", "BLEED_UP"
};

static NSString * const _str_bakerShaderPicker = @"bakerShader";

@interface ImageBakerView() {
    int _currentMode;
}

@end
@implementation ImageBakerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

+(NSDictionary *)shakerModes
{
    NSDictionary * shaders = @{ @(__bakerShakerModes[0]): @"I blue you down",
                                @(__bakerShakerModes[1]): @"You burned me",
                                @(__bakerShakerModes[2]): @"Heated up"};
    
    return shaders;
    
}
-(NSArray *)getSettings
{
    NSArray * arr = [super getSettings];
    NSDictionary * shaders = [ImageBakerView shakerModes];
    
    SettingsDescriptor * sd = [[SettingsDescriptor alloc] initWithControlType: SC_Picker
                                                                   memberName: _str_bakerShaderPicker
                                                                    labelText: @"Effect"
                                                                      options: shaders
                                                                     selected: @(__bakerShakerModes[_currentMode])
                                                                     delegate: self
                                                                     priority: SHADER_SETTINGS];
    
    return [arr arrayByAddingObject:sd];
    
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    
	return @(__bakerShakerModes[row]);
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSLog(@"row: %d",row);
	{
		/*
         label.text = [NSString stringWithFormat:@"%@ - %d",
         pickerViewArray[[pickerView selectedRowInComponent:0]],
         [pickerView selectedRowInComponent:1]];
         */
	}
}

@end
