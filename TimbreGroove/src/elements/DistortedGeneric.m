//
//  DistortedGeneric.m
//  
//
//  Created by victor on 2/6/13.
//
//

#import "DistortedGeneric.h"
#import "PointRecorder.h"
#import "GraphView.h"


@interface DistortedGeneric () {
    PointPlayer * _player;
    NSTimeInterval _dTimer;
}
@end

@implementation DistortedGeneric

-(void)setDistortionFactor:(float)distortionFactor
{
    [self.shader writeToLocation:gv_distortionFactor type:TG_FLOAT data:&distortionFactor];
    _distortionFactor = distortionFactor;
}

-(void)didAttachToView:(GraphView *)view
{
    [super didAttachToView:view];
    [view.recordGesture addReceiver:self];
}

-(void)didDetachFromView:(GraphView *)view
{
    [super didDetachFromView:view];
    [view.recordGesture removeReceiver:self];
}

-(NSString *)getShaderHeader
{
    return [[super getShaderHeader] stringByAppendingString:@"\n#define DISTORTION"];
}

-(void)RecordGesture:(RecordGesture*)rg recordingWillBegin:(PointRecorder *)recorder
{
    GLKVector3 pt = (GLKVector3){0,0,0};
    [self.shader writeToLocation:gv_distortionPt type:TG_VECTOR3 data:pt.v];
    _player = nil;
}

-(void)RecordGesture:(RecordGesture*)rg recordingBegan:(PointRecorder *)recorder
{
    _player = nil;
}

-(void)RecordGesture:(RecordGesture*)rg recordedPt:(GLKVector3)pt
{
    [self.shader writeToLocation:gv_distortionPt type:TG_VECTOR3 data:pt.v];
}

-(void)RecordGesture:(RecordGesture*)rg recordingDone:(PointRecorder *)recorder
{
    _player = [recorder makePlayer];
    _dTimer = 0;
}

-(void)update:(NSTimeInterval)dt mixerUpdate:(MixerUpdate *)mixerUpdate
{
    [super update:dt mixerUpdate:mixerUpdate];
    _dTimer += dt;
    if( _player && (_dTimer > _player.duration) )
    {
        _dTimer = 0;
        GLKVector3 pt = _player.next;
        [self.shader writeToLocation:gv_distortionPt type:TG_VECTOR3 data:pt.v];
    }
}

@end
