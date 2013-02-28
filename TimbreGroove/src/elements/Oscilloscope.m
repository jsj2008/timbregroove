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
#import "NSValue+Parameter.h"

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

-(NSDictionary *)getParameters
{
    NSMutableDictionary * dict = (NSMutableDictionary *)[super getParameters];
    
    dict[@"AudioFrameDisplay"] = ^(NSValue *value ) {
        MixerUpdate mu = [value MixerUpdateValue];
        AudioBufferList * abl = mu.audioBufferList;
        if( abl )
        {
            _lineMesh.heightOffsets = abl->mBuffers[0].mData;
            [_lineMesh resetVertices];
        }
    };
    
    return dict;
    
}

-(void)update:(NSTimeInterval)dt
{
    [super update:dt];
    
}

@end
