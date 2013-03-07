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

-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];
    
    putHere[@"frameCapture"] = [Parameter withBlock:^(void *ptr) {
        if( ptr )
        {
            _lineMesh.heightOffsets = ((AudioBufferList *)ptr)->mBuffers[0].mData;
            [_lineMesh resetVertices];
        }
    }];
}


@end
