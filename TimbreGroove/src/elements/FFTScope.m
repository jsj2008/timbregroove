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
#import "Names.h"

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
    self.position = (GLKVector3){ 0, -M_PI_2, 0 };
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
    
    putHere[kParamAudioFrameCapture] = [Parameter withBlock:^(void *ptr) {
#ifdef DEBUG
        static int capCount = 0;
        if( capCount++ % 120 == 0 )
            TGLog(LLCaptureOps, @"FFT Capture buffer: %p",ptr);
#endif
        if( ptr )
        {
#ifdef AUDIO_BUFFER_NATIVE_FLOATS
            AudioBufferList * abl = (AudioBufferList *)ptr;
            memcpy( _data,abl->mBuffers[0].mData, sizeof(_data) );
#else
            UInt32 * intData = ((AudioBufferList *)ptr)->mBuffers[0].mData;
            for( int i = 0; i < kFramesForDisplay; i++ )
            {
                SInt16 i16 = (SInt16)(intData[i] >> 9);
                _data[i] = ((float)i16 / 32768.0) * 0.2;
            }
            
#endif
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
