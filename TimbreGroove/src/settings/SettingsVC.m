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
                initialValue:(id)initialValue
                priority:(int)priority
{
    if( (self = [super init]) )
    {
        _controlType = cType;
        _memberName = memberName;
        _labelText = text;
        _options = values;
        _initialValue = initialValue;
        _priority = priority;
    }
    
    return self;
}

@end

@interface SettingsVC () {
    NSMutableDictionary * _settingsDict;
    NSMutableDictionary * _dynamicProps;
}
@end

@implementation SettingsVC


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

-(IBAction)backToHome:(id)sender {
    [self.caresDeeply settingsGoingAway:self];
    [self.navigationController popToRootViewControllerAnimated:YES];
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
            break;
            
        case SC_Switch:
            control = [self createSwitch:sd];
            break;

        case SC_Picture:
            control = [self createPicturePicker:sd];
            break;
            
        default:
            break;
    }
    
    return control;
}

-(NSArray *)setupConstraintsFor:(UIView *)control
                          label:(UILabel *)label
                           prev:(UIView *)prevControl
{
    NSDictionary *viewsDictionary = @{
                    prevControl.memberName: prevControl,
                    label.memberName: label,
                    control.memberName: control};
    
    // V:[prevControl]-[label]
    // V:[prevControl]-[control]
    // H:!-[label(==100)]-[control]-|
    NSString * VFL1 = [NSString stringWithFormat:@"V:[%@]-[%@]",prevControl.memberName,label.memberName];
    NSString * VFL2 = [NSString stringWithFormat:@"V:[%@]-[%@]",prevControl.memberName,control.memberName];
    NSString * VFL3 = [NSString stringWithFormat:@"H:|-[%@(==100)]-[%@]-|",label.memberName,control.memberName];

    NSArray * c1 = [NSLayoutConstraint constraintsWithVisualFormat:VFL1
                                                           options:0
                                                           metrics:nil
                                                             views:viewsDictionary];
    
    NSArray * c2 = [NSLayoutConstraint constraintsWithVisualFormat:VFL2
                                                           options:0
                                                           metrics:nil
                                                             views:viewsDictionary];

    NSArray * c3 = [NSLayoutConstraint constraintsWithVisualFormat:VFL3
                                                           options:0
                                                           metrics:nil
                                                             views:viewsDictionary];

    NSMutableArray * arr = [[NSMutableArray alloc] initWithArray:c1];
    [arr addObjectsFromArray:c2];
    [arr addObjectsFromArray:c3];
    return arr;
}

-(UILabel *)labelForControl:(SettingsDescriptor *)sd example:(UILabel *)example
{
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [label setText:sd.labelText];
    label.memberName = [sd.memberName stringByAppendingString:@"_label"];
    [self.view addSubview:label];
    
    label.textAlignment = NSTextAlignmentRight;
    label.opaque = example.opaque;
    label.textColor = example.textColor;
    label.backgroundColor = example.backgroundColor;

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
        UILabel * label = [self labelForControl:sd example:_componentTitleLabel];
        [constraints addObjectsFromArray:[self setupConstraintsFor:control label:label prev:prevControl]];
        prevControl = control;
    }
    [self.view addConstraints:constraints];
    _settings = nil; // don't need this anymore
}

- (UIView *)createPicturePicker:(SettingsDescriptor *)sd
{
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    controller.mediaTypes = @[(__bridge NSString *)kUTTypeImage];
    controller.allowsEditing = YES;
    controller.delegate = self;
    [self addDynoProp:controller forKey:sd.memberName];
    
    
    UIButton * button = [self createButtonHelper:sd title:sd.initialValue];
    [button addTarget:self action:@selector(onPicturePickerButton:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

-(void)onPicturePickerButton:(UIButton *)sender
{
    NSString * pickerName = [sender.memberName componentsSeparatedByString:@"_"][0];    
    UIImagePickerController * controller = [self valueForKey:pickerName];
    [self presentViewController:controller animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // UIImagePickerControllerReferenceURL
    // UIImagePickerControllerReferenceURL
    NSURL * url = info[UIImagePickerControllerReferenceURL];
    NSLog(@"Got media url %@",url);
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (UIView *)createSwitch:(SettingsDescriptor *)sd
{
    UISwitch * sw = [[UISwitch alloc] initWithFrame:CGRectZero];
    sw.translatesAutoresizingMaskIntoConstraints = NO;
    sw.on = [sd.initialValue intValue];;
    [sw addTarget:self action:@selector(switchThrown:) forControlEvents:UIControlEventValueChanged];
    sw.memberName = sd.memberName;
    [self.view addSubview:sw];
    return sw;
}

-(void)switchThrown:(UISwitch *)sw
{
    NSString           * name   = sw.memberName;
    SettingsDescriptor * sd     = _settingsDict[name];
    
    [sd.options[@"target"] setValue:@(sw.on) forKey:sd.options[@"key"]];
}

- (UIControl *)createSlider:(SettingsDescriptor *)sd
{
    UISlider * slider = [[UISlider alloc] initWithFrame:CGRectZero];
    slider.translatesAutoresizingMaskIntoConstraints = NO;
    slider.minimumValue = [sd.options[@"low"] floatValue];
    slider.maximumValue = [sd.options[@"high"] floatValue];
    slider.value = [sd.initialValue floatValue];
    [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    slider.memberName = sd.memberName;
    [self.view addSubview:slider];
    return slider;
}

-(void)sliderValueChanged:(UISlider *)slider
{
    NSString           * name   = slider.memberName;
    SettingsDescriptor * sd     = _settingsDict[name];
    
    [sd.options[@"target"] setValue:@(slider.value) forKey:sd.options[@"key"]];
}

-(UIControl *)createText:(SettingsDescriptor *)sd
{
    UITextField * textField = [[UITextField alloc] initWithFrame:CGRectZero];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    [textField setText:sd.initialValue];
    textField.memberName = sd.memberName;
    [self.view addSubview:textField];
    [textField addTarget:self action:@selector(textEditingDidEnd:) forControlEvents:UIControlEventEditingDidEnd];
    
    return textField;    
}

-(void)textEditingDidEnd:(UITextField *)tfield
{
    NSString           * name   = tfield.memberName;
    SettingsDescriptor * sd     = _settingsDict[name];
    
    [sd.options[@"target"] setValue:tfield.text forKey:sd.options[@"key"]];
    
}

- (UIControl *)createPicker:(SettingsDescriptor *)sd
{
	// note we are using CGRectZero for the dimensions of our picker view,
	// this is because picker views have a built in optimum size,
	// you just need to set the correct origin in your view.
	//
	// position the picker at the bottom
	UIPickerView * picker = [[UIPickerView alloc] initWithFrame:CGRectZero];
	picker.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	CGSize size       = [picker sizeThatFits:CGSizeZero];
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	picker.frame      = CGRectMake(	0.0,
                                   screenRect.size.height - 42.0 - size.height,
                                   size.width,
                                   size.height);
    
    picker.memberName = sd.memberName;
	picker.delegate = self;
	picker.dataSource = self; // really?
	picker.showsSelectionIndicator = YES;	// note this is default to NO
	picker.hidden = YES;
    
    [picker selectRow:[self getKeyIndex:sd] inComponent:0 animated:NO];
    
	[self.view addSubview:picker];
    
    UIButton * button = [self createButtonHelper:sd title:sd.options[@"values"][sd.initialValue]];
    [button addTarget:self action:@selector(onPickerButton:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

-(int)getKeyIndex:(SettingsDescriptor *)sd
{
    int count = 0;
    for( id key in sd.options[@"values"] )
    {
        if ([key isEqual:sd.initialValue]) {
            return count;
        }
        ++count;
    }
#if DEBUG
    NSLog(@"Can't find key %@ in values array",sd.initialValue);
    exit(1);
#endif
    return 0;
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
    NSString           * name   = pickerView.memberName;
    SettingsDescriptor * sd     = _settingsDict[name];
    NSDictionary       * values = sd.options[@"values"];
    
    UIButton * button = [self valueForKey:[name stringByAppendingString:@"_button"]];
    [button setTitle:[values allValues][row] forState:UIControlStateNormal];
    
    [sd.options[@"target"] setValue:[values allKeys][row] forKey:sd.options[@"key"]];
    
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    SettingsDescriptor * sd = _settingsDict[pickerView.memberName];
    return [sd.options[@"values"] allValues][row];
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    SettingsDescriptor * sd = _settingsDict[pickerView.memberName];
    return [sd.options[@"values"] count];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

-(UIButton *)createButtonHelper:(SettingsDescriptor *)sd title:(NSString *)title
{
    UIButton * button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:title forState:UIControlStateNormal];
    [self.view addSubview:button];
    button.memberName = [sd.memberName stringByAppendingString:@"_button"];
    return button;
}

-(void)addDynoProp:(id)value forKey:(NSString *)key
{
    if( !_dynamicProps )
        _dynamicProps = [NSMutableDictionary new];
    _dynamicProps[key] = value;
}

-(id)valueForUndefinedKey:(NSString *)key
{
    for( UIView * view in self.view.subviews )
    {
        if( [key isEqualToString:view.memberName] )
            return view;
    }
    for( NSString * dkey in _dynamicProps )
    {
        if( [dkey isEqualToString:key] )
            return _dynamicProps[dkey];
    }
    return nil;
}

@end
