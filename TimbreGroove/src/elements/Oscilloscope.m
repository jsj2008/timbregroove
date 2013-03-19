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
#import "Names.h"

@interface Oscilloscope : Generic

@end

@interface Oscilloscope () {
    float _data[kFramesForDisplay];
    __weak Line * _lineMesh;
}
@end

@implementation Oscilloscope

-(id)wireUp
{
    [super wireUp];
 //   self.scale = (GLKVector3) { 1.0, 1.0/60.0, 1.0 };
    return self;
}

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
    
    putHere[kParamAudioFrameCapture] = [Parameter withBlock:^(void *ptr) {
#ifdef DEBUG
        static int capCount = 0;
        if( capCount++ % 120 == 0 )
            TGLog(LLCaptureOps, @"Capture buffer: %p",ptr);
#endif
        if( ptr )
        {
#ifdef AUDIO_BUFFER_NATIVE_FLOATS
            _lineMesh.heightOffsets = ((AudioBufferList *)ptr)->mBuffers[0].mData;
#else
            UInt32 * intData = ((AudioBufferList *)ptr)->mBuffers[0].mData;
            for( int i = 0; i < kFramesForDisplay; i++ )
            {
                SInt16 i16 = (SInt16)(intData[i] >> 9);
                _data[i] = (float)i16 / (float)0x10000;
            }
            _lineMesh.heightOffsets = _data;
#endif
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
