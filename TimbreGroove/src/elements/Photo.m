//
//  Photo.m
//  TimbreGroove
//
//  Created by victor on 12/21/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Photo.h"
#import "SettingsVC.h"
#import "Texture.h"
#import "GridPlane.h"
#import "PointRecorder.h"

#import "GraphView.h"

static NSString * __str_pictureFieldName = @"picturePicker";

@interface Photo () {
    PointPlayer * _player;
}

@end
@implementation Photo

-(id)wireUp
{
    if( !self.textureFileName )
        self.textureFileName = @"Alex.png";
    return [super wireUp];
}

-(void)createBuffer
{
    GridPlane * gp = [GridPlane gridWithWidth:2.0
                                     andGrids:20
                          andIndicesIntoNames:@[@(gv_pos),@(gv_uv)]
                                     andDoUVs:true
                                 andDoNormals:false];
    [self addBuffer:gp];
}

-(void)didAttachToView:(GraphView *)view
{
    [view.recordGesture addReceiver:self];
}

-(void)didDetachFromView:(GraphView *)view
{
    [view.recordGesture removeReceiver:self];
}

-(NSString *)getShaderHeader
{
    return [[super getShaderHeader] stringByAppendingString:@"\n#define DISTORTION"];
}

-(void)RecordGesture:(RecordGesture*)rg recordingBegin:(PointRecorder *)recorder
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
    _timer = 0;
}

-(void)update:(NSTimeInterval)dt
{
    if( _player && (_timer > _player.duration) )
    {
        _timer = 0;
        GLKVector3 pt = _player.next;
        [self.shader writeToLocation:gv_distortionPt type:TG_VECTOR3 data:pt.v];
    }
}

-(void)setTexture:(Texture *)texture
{
    [super setTexture:texture];
    if( self.texture )
    {
        CGSize sz = self.texture.orgSize;
        GLKVector3 scale = { 1, 1, 1 };
        if( sz.height > sz.width )
        {
            scale.y = sz.height / sz.width;
        }
        else if ( sz.width > sz.height )
        {
            scale.x = sz.width / sz.height;
        }
        self.scale = scale;
    }
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
