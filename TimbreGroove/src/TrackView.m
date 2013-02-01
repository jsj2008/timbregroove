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
#import "BlendState.h"

#import "Generic.h"
#import "GridPlane.h"
@interface GreySq : Generic
@end;

@implementation GreySq

-(id)wireUp
{
    self.camera = [IdentityCamera new];
    self.color = (GLKVector4){ 0.3, 0.3, 0.5, 1.0 };
    return [super wireUp];
}

-(void)createBuffer
{
    GridPlane * gp = [GridPlane gridWithIndicesIntoNames:@[@(gv_pos)]
                                                andDoUVs:false
                                            andDoNormals:false];
    [self addBuffer:gp];
}

@end


@interface TrackView () {
    Generic * _greySquare;
}

@end

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
    self.graph.camera.position = pos;
    _backcolor = (GLKVector4){0.1, 0.1, 0.1, 0.4};
}

-(void)update:(NSTimeInterval)dt
{
    if( _playMode == tpm_play )
    {
        [super update:dt];
    }
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    if( _playMode == tpm_pause )
    {
        if( !_greySquare )
            _greySquare = [[GreySq new] wireUp];
        BlendState * bs = [BlendState enable:true
                                   srcFactor:GL_DST_ALPHA
                                   dstFactor:GL_SRC_COLOR];
        [_greySquare render:rect.size.width h:rect.size.height];
        [bs restore];
    }
}


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
