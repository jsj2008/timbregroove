//
//  FFTScope.m
//  TimbreGroove
//
//  Created by victor on 3/9/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Geometry.h"
#import "Line.h"
#import "SoundSystem.h"
#import "Parameter.h"
#import "Generic.h"


extern void fft(float *in_out, int len);

@interface FFTScope : Generic {
    __weak Line * _lineMesh;
    float _data[kFramesForDisplay];
}

@end

@implementation FFTScope

-(id)wireUp
{
    [super wireUp];
    
    self.scale = (GLKVector3){ 1, 1.0/(M_PI_2), 1 };
    self.position = (GLKVector3){ 0, -1.0, 0 };
    return self;
    
}

-(void)createBuffer
{
    self.color = (GLKVector4){ 1, 1, 0.4, 1};
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
            AudioBufferList * abl = (AudioBufferList *)ptr;
            memcpy( _data,abl->mBuffers[0].mData, sizeof(_data) );
            fft(_data, kFramesForDisplay);
            
            float scaled[kFramesForDisplay];
            float * p = scaled;
            for( int i = 0; i < kFramesForDisplay; i++ )
            {
                float arct = atanf(_data[i]);
                *p++ = arct * arct;
            }
            _lineMesh.heightOffsets = scaled;
            [_lineMesh resetVertices];
        }
    }];
}

@end
