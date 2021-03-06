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
#import "Painter.h"
#import "Material.h"
#import "Names.h"
#import "Light.h"

extern void fft(float *in_out, int len);

@interface FFTScope : Painter {
    __weak Line * _lineMesh;
    float _data[kFramesForDisplay];

}

@end

@implementation FFTScope

-(id)wireUp
{
    [super wireUp];
    
    self.scale = (GLKVector3){ 1, 1.0/(M_PI_2), 1 };
    self.position = (GLKVector3){ 0, -M_PI_2, 0 };
    return self;
    
}

-(void)createBuffer
{
    Line * mesh = [[Line alloc] initWithIndicesIntoNames:@[@(gv_pos)]
                                               isDynamic:true
                                                 spacing:kFramesForDisplay];
    _lineMesh = mesh;
    [self addBuffer:mesh];
}

-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];
    
    putHere[kParamAudioFrameCapture] = [Parameter withBlock:^(void *ptr) {
#ifdef DEBUG
        static int capCount = 0;
        if( capCount++ % 120 == 0 )
            TGLog(LLCaptureOps, @"FFT Capture buffer: %p",ptr);
#endif
        if( ptr )
        {
            AudioBufferList * abl = (AudioBufferList *)ptr;
            memcpy( _data,abl->mBuffers[0].mData, sizeof(_data) );
            fft(_data, kFramesForDisplay);
            
            for( int i = 0; i < kFramesForDisplay; i++ )
            {
                float arct = atanf(_data[i]);
                _data[i] = arct * arct;
            }
            _lineMesh.heightOffsets = _data;
            [_lineMesh resetVertices];
        }
    }];
    
#ifdef DEBUG
    TGLog(LLCaptureOps, @"Posting cap parameter: %@", (__bridge void *)putHere[kParamAudioFrameCapture]);
#endif
}

#ifdef DEBUG
-(void)triggersChanged:(Scene *)scene
{
    TGLog(LLCaptureOps, @"Capturing for %@ in %@",self,scene);
}
#endif

@end
