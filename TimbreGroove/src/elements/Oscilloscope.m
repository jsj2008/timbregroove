//
//  Oscilloscope.m
//  TimbreGroove
//
//  Created by victor on 2/12/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Geometry.h"
#import "Line.h"
#import "SoundSystem.h"
#import "Parameter.h"
#import "Generic.h"

@interface Oscilloscope : Generic

@end

@interface Oscilloscope () {
    float _data[kFramesForDisplay];
    __weak Line * _lineMesh;
}
@property (nonatomic) NSValue * frameCapture;
@end

@implementation Oscilloscope

-(void)createBuffer
{
    self.color = (GLKVector4){ 0.4, 1, 0.4, 1};
    Line * mesh = [[Line alloc] initWithIndicesIntoNames:@[@(gv_pos)]
                                               isDynamic:true
                                                 spacing:kFramesForDisplay];
    _lineMesh = mesh;
    [self addBuffer:mesh];
}

-(void)setFrameCapture:(NSValue *)nsv
{
    AudioFrameCapture frameCapture = [nsv AudioFrameCaptureValue];
    AudioBufferList * abl = frameCapture.audioBufferList;
    if( abl )
    {
        _lineMesh.heightOffsets = abl->mBuffers[0].mData;
        [_lineMesh resetVertices];
    }
    
}
-(void)getParameters:(NSMutableDictionary *)putHere
{
    PropertyParameter * pp = [[NonAnimatingPropertyParameter alloc] initWithTarget:self
                                                                           andName:@"frameCapture"];
    [super getParameters:putHere];
    [self appendParameters:putHere withProperties:@[pp]];
}


@end
