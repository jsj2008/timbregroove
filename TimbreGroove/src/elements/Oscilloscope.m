//
//  Oscilloscope.m
//  TimbreGroove
//
//  Created by victor on 2/12/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Oscilloscope.h"
#import "Geometry.h"
#import "Line.h"
#import "Mixer.h"

@interface Oscilloscope () {
    float _data[kFramesForDisplay];
    __weak Line * _lineMesh;
}

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

-(void)setSounds
{
    self.soundName = @"ambience";
    [self.sound playMidiFile:@"simpleMel"];
}

-(void)update:(NSTimeInterval)dt mixerUpdate:(MixerUpdate *)mixerUpdate
{
    [super update:dt mixerUpdate:mixerUpdate];
    
    AudioBufferList * abl = mixerUpdate->audioBufferList;
    if( abl )
    {
        _lineMesh.heightOffsets = abl->mBuffers[0].mData;
        [_lineMesh resetVertices];
    }
}

@end
