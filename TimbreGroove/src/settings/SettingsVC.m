//
//  SettingsVC.m
//  TimbreGroove
//
//  Created by victor on 1/2/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "SettingsVC.h"
#import "Sound.h"

@implementation SettingsDescriptor

-(id)initWithControlType:(SettingControl)cType
              memberName:(NSString *)memberName
               labelText:(NSString *)text
                  options:(NSDictionary *)values
                selected:(id)selected
                delegate:(id)delegate
                priority:(int)priority
{
    if( (self = [super init]) )
    {
        _controlType = cType;
        _memberName = memberName;
        _labelText = text;
        _options = values;
        _initialValue = selected;
        _delegate = delegate;
        _priority = priority;
    }
    
    return self;
}

@end

@interface SettingsVC () {
    NSMutableDictionary * _settingsDict;
}
@end

@implementation SettingsVC

-(IBAction)backToHome:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self installControls];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIView *)createControl:(SettingsDescriptor *)sd
{
    UIView * control = nil;

    switch (sd.controlType) {
        case SC_Picker:
            control = [self createPicker:sd];
            break;
            
        case SC_Slider:
            control = [self createSlider:sd];
            break;
            
        case SC_Text:
            control = [self createText:sd];
            
        default:
            break;
    }
    
    return control;
}

-(NSArray *)setupConstraintsFor:(UIView *)control
                          label:(UILabel *)label
                           prev:(UIView *)prevControl
{
    // V:[prevControl]-[label]
    // H:!-[label(==100)]-[control]-|
    NSString * VFL1 = [NSString stringWithFormat:@"V:[%@]-[%@]",prevControl.memberName,label.memberName];
    NSString * VFL2 = [NSString stringWithFormat:@"H:|-[%@(==100)]-[%@]-|",label.memberName,control.memberName];

    NSDictionary *viewsDictionary = @{
            prevControl.memberName: prevControl,
                  label.memberName: label,
                control.memberName: control};
    
    NSArray * c1 = [NSLayoutConstraint constraintsWithVisualFormat:VFL1
                                                           options:0
                                                           metrics:nil
                                                             views:viewsDictionary];
    
    NSArray * c2 = [NSLayoutConstraint constraintsWithVisualFormat:VFL2
                                                           options:0
                                                           metrics:nil
                                                             views:viewsDictionary];
    
    NSMutableArray * arr = [[NSMutableArray alloc] initWithArray:c1];
    [arr addObjectsFromArray:c2];
    return arr;
}

-(UILabel *)labelForControl:(SettingsDescriptor *)sd
{
    UILabel * label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [label setText:sd.labelText];
    label.memberName = [sd.memberName stringByAppendingString:@"_label"];
    //[self setValue:label forKey:label.memberName];
    return label;
}

-(void)installControls
{   
    _settings = [_settings sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return ((SettingsDescriptor *)obj1).priority < ((SettingsDescriptor *)obj2).priority ?
                                  NSOrderedAscending : NSOrderedDescending;
    }];
    _settingsDict = [[NSMutableDictionary alloc] initWithCapacity:[_settings count]];
    UIView * prevControl = _componentTitleLabel;
    prevControl.memberName = @"_componentTitleLabel";
    
    NSMutableArray * constraints = [NSMutableArray new];

    for( SettingsDescriptor * sd in _settings )
    {
        _settingsDict[sd.memberName] = sd;
        UIView * control = [self createControl:sd];
        UILabel * label = [self labelForControl:sd];
        [constraints addObjectsFromArray:[self setupConstraintsFor:control label:label prev:prevControl]];
    }
    _settings = nil; // don't need this anymore
}

- (UIControl *)createSlider:(SettingsDescriptor *)sd
{
    UISlider * slider = [[UISlider alloc] init];
    slider.translatesAutoresizingMaskIntoConstraints = NO;
    slider.minimumValue = [sd.options[@"low"] floatValue];
    slider.maximumValue = [sd.options[@"high"] floatValue];
    slider.value = [sd.initialValue floatValue];
#if DEBUG
    if( ![sd.delegate canPerformAction:@selector(sliderValueChanged:) withSender:slider] )
    {
        NSLog(@"request for slider when SettingsDescriptor.delegate does not implement 'slidverValueChanged:' message");
        exit(1);
    }
#endif
    [slider addTarget:sd.delegate action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    slider.memberName = sd.memberName;
    [self.view addSubview:slider];
    //[self setValue:slider forKey:sd.memberName];
    return slider;
}

-(UIControl *)createText:(SettingsDescriptor *)sd
{
    UITextField * textField = [UITextField new];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    [textField setText:sd.initialValue];
    textField.memberName = sd.memberName;
    [self.view addSubview:textField];
    //[self setValue:textField forKey:textField.memberName];
#if DEBUG
    if( ![sd.delegate canPerformAction:@selector(textEditingEnded:) withSender:textField] )
    {
        NSLog(@"request for textEdit when SettingsDescriptor.delegate does not implement 'textEditingEnded:' message");
        exit(1);
    }
#endif
    [textField addTarget:sd.delegate action:@selector(textEditValueChanged:) forControlEvents:UIControlEventEditingDidEnd];
    
    return textField;    
}

// return the picker frame based on its size, positioned at the bottom of the page
- (CGRect)pickerFrameWithSize:(CGSize)size
{
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	CGRect pickerRect = CGRectMake(	0.0,
                                   screenRect.size.height - 42.0 - size.height,
                                   size.width,
                                   size.height);
	return pickerRect;
}

- (UIControl *)createPicker:(SettingsDescriptor *)sd
{
	// note we are using CGRectZero for the dimensions of our picker view,
	// this is because picker views have a built in optimum size,
	// you just need to set the correct origin in your view.
	//
	// position the picker at the bottom
	UIPickerView * picker = [[UIPickerView alloc] initWithFrame:CGRectZero];
    picker.memberName = sd.memberName;

	picker.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	CGSize pickerSize = [picker sizeThatFits:CGSizeZero];
	picker.frame = [self pickerFrameWithSize:pickerSize];
    
	picker.showsSelectionIndicator = YES;	// note this is default to NO
	
	picker.delegate = self;
	picker.dataSource = self; // really?
	
	picker.hidden = YES;
	[self.view addSubview:picker];
    //[self setValue:picker forKey:sd.memberName];
    
    UIButton * button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    NSString * selectedValue = sd.options[sd.initialValue];
    [button setTitle:selectedValue forState:UIControlStateNormal];
    [self.view addSubview:button];
    button.memberName = [sd.memberName stringByAppendingString:@"_button"];
    [button addTarget:self action:@selector(onPickerButton:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

-(IBAction)onPickerButton:(UIButton *)sender
{
    NSString * pickerName = [sender.memberName componentsSeparatedByString:@"_"][0];
    UIPickerView * picker = [self valueForKey:pickerName];
    if( picker.hidden )
        picker.hidden = NO;
    else
        picker.hidden = YES;
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component
{
    NSString * name = pickerView.memberName;
    UIButton * button = [self valueForKey:[name stringByAppendingString:@"_button"]];
    SettingsDescriptor * sd = _settingsDict[name];
    NSString * selectedValue = [sd.options allValues][row];
    [button setTitle:selectedValue forState:UIControlStateNormal];

/* something like this (without forcing conforming to UIViewPickDelegate
    if( ![sd.delegate canPerformAction:@selector(textEditingEnded:) withSender:textField] )
    {
        NSLog(@"request for textEdit when SettingsDescriptor.delegate does not implement 'textEditingEnded:' message");
        exit(1);
    }
*/
    
    id<UIPickerViewDelegate> proxy = sd.delegate;
    return [proxy pickerView:pickerView didSelectRow:row inComponent:component];
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    SettingsDescriptor * sd = _settingsDict[pickerView.memberName];
    return [sd.options allValues][row];
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    SettingsDescriptor * sd = _settingsDict[pickerView.memberName];
    return [sd.options count];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

-(id)valueForUndefinedKey:(NSString *)key
{
    NSArray * controls = self.view.subviews;
    NSIndexSet * index = [controls indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        bool match = ((UIView *)obj).memberName == key;
        *stop = match;
        return match;
    }];
    
    if( [index count] )
        return controls[[index firstIndex]];
    
    return nil;
}

@end
