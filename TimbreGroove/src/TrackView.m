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
#import "SettingsVC.h"

@implementation TrackView

-(void)createNode:(NSDictionary *)params;
{
    Class klass = NSClassFromString(params[@"instanceClass"]);
    TG3dObject * node = [[klass alloc] init];
    node.view = self;
    [self.graph appendChild:node];
    [node setValuesForKeysWithDictionary:params];
    [node wireUp];
}

-(void)setupGL
{
    [super setupGL];
    GLKVector3 pos = { 0, 0, CAMERA_DEFAULT_Z };
    _graph.camera.position = pos;
    _backcolor = GLKVector4Make(0.1, 0.1, 0.1, 1);
}

-(void)showAnimationComplete
{
    [self setupGL];
    [_graph traverse:@selector(setViewIsHidden:) userObj:[[NSNumber alloc] initWithBool:false]];    
}

- (void)showFromDir:(int)dir
{
    _visible = true;
    
    CGRect rc = self.frame;
    rc.origin.x = rc.size.width * dir;
    self.frame = rc;
    NSDictionary * params = @{  TWEEN_DURATION: @0.7f,
                                TWEEN_TRANSITION: TWEEN_FUNC_EASEOUTSINE,
                        TWEEN_ON_COMPLETE_SELECTOR: @"showAnimationComplete",
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
                    TWEEN_ON_COMPLETE_SELECTOR: @"hideAnimationComplete",
                      TWEEN_ON_COMPLETE_TARGET: self
    };
    
    [Tweener addTween:self withParameters:params];
}

-(void)hideAnimationComplete
{
    [super hideAnimationComplete];
    [_graph traverse:@selector(setViewIsHidden:) userObj:[[NSNumber alloc] initWithBool:true]];
}

-(void)setMenuIsOver:(NSNumber *)menuIsOver
{
    [_graph traverse:@selector(setViewIsObscured:) userObj:menuIsOver];
    _menuIsOver = menuIsOver;
}

#if DEBUG
-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect]; // for breakpoint setting
}
#endif


-(NSArray *)getSettings
{
    return [[self.graph firstChild] getSettings];
}

/*
-(NSArray *)getSoundSettings
{
    TG3dObject * obj = self.firstNode;
    SettingsDescriptor * sdv= [[SettingsDescriptor alloc] initWithControlType: SC_Slider
                                                                   memberName: _str_volumeSlider
                                                                    labelText: @"Volume"
                                                                      options: @{@"low":@0.0f,@"high":@1.0f,
                                                                                 @"target":obj.sound,@"key":@"volume"}
                                                                initialValue:@(obj.sound.volume)
                                                                     priority: AUDIO_SETTINGS];

    SettingsDescriptor * sdm= [[SettingsDescriptor alloc] initWithControlType: SC_Switch
                                                                   memberName: _str_userMuteSwitch
                                                                    labelText: @"Mute"
                                                                      options: @{ @"target":self, @"key":@"userMuted"}
                                                                 initialValue: @(self.userMuted)
                                                                     priority: AUDIO_SETTINGS+1];

    return @[sdv,sdm];
}
*/

-(void)settingsGoingAway:(SettingsVC *)vc;
{
    for( TG3dObject *obj in self.graph.children )
    {
        if( obj.needsRewire )
            [obj rewire];
    }
}

@end
