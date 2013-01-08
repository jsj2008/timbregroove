//
//  TrackView.m
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TrackView.h"
#import "Graph.h"
#import "Camera.h"
#import "Tweener.h"
#import "Tween.h"
#import "TG3dObject+Sound.h"
#import "Sound.h"
#import "SettingsVC.h"

static NSString * _str_volumeSlider = @"_volumeSlider";


@implementation TrackView

-(void)createNode:(NSDictionary *)params;
{
    Class klass = NSClassFromString(params[@"instanceClass"]);
    TG3dObject * node = [[klass alloc] initWithObject:self];
    [node assignSound:params];
    [self.graph appendChild:node];
}

-(void)setupGL
{
    [super setupGL];
    GLKVector3 pos = { 0, 0, CAMERA_DEFAULT_Z };
    _graph.camera.position = pos;
    _backcolor = GLKVector4Make(0.1, 0.1, 0.1, 1);
}

- (void)showFromDir:(int)dir
{
    _visible = true;
    
    CGRect rc = self.frame;
    rc.origin.x = rc.size.width * dir;
    self.frame = rc;
    NSDictionary * params = @{  TWEEN_DURATION: @0.7f,
                                TWEEN_TRANSITION: TWEEN_FUNC_EASEOUTSINE,
                        TWEEN_ON_COMPLETE_SELECTOR: @"setupGL",
                        TWEEN_ON_COMPLETE_TARGET: self,
                                            @"x": @(0)
    };
    
    [Tweener addTween:self withParameters:params];
}

- (void)hideToDir:(int)dir
{
    CGRect rc = self.frame;
    NSDictionary * params = @{  TWEEN_DURATION: @0.7f,
                              TWEEN_TRANSITION: TWEEN_FUNC_EASEOUTSINE,
                                          @"x": @(rc.size.width*dir),
                    TWEEN_ON_COMPLETE_SELECTOR: @"markHidden",
                      TWEEN_ON_COMPLETE_TARGET: self
    };
    
    [Tweener addTween:self withParameters:params];
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
}

-(void)markHidden
{
    _visible = false;
}

-(NSArray *)getSettings
{
    return [self getSoundSettings];
}

-(NSArray *)getSoundSettings
{
    TG3dObject * obj = self.firstNode;
    SettingsDescriptor * sd = [[SettingsDescriptor alloc] initWithControlType: SC_Slider
                                                                   memberName: _str_volumeSlider
                                                                    labelText: @"Volume"
                                                                      options: @{@"low":@0.0f,@"high":@1.0f}
                                                                     selected: @(obj.sound.volume)
                                                                     delegate: self
                                                                     priority: AUDIO_SETTINGS];

    return @[sd];
}

-(void)sliderValueChanged:(UISlider *)slider
{
    if( slider.memberName == _str_volumeSlider)
    {
        TG3dObject * obj = self.firstNode;
        obj.sound.volume = slider.value;
    }
}

@end
