//
//  EQPanel.m
//  TimbreGroove
//
//  Created by victor on 2/14/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "EQPanel.h"
#import "Mixer.h"
#import "Mixer+Parameters.h"

@interface EQPanel ()
@end

@implementation EQPanel

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    eqBands bands[2] = { kEQLow, kEQHigh };
    GLKVector4 colors[2] = {
        { 0.5, 0.8, 1, 1 },
        { 0.5, 1, 0.5, 1 }
    };
    Mixer * mixer = [Mixer sharedInstance];

    for( int i = 0; i < 2; i++ )
    {
        self.color = colors[i];
        mixer.selectedEQBand = bands[i];
        AudioUnitParameterValue peak   = mixer.eqPeak + 0.5;
        AudioUnitParameterValue center = mixer.eqCenter;
        AudioUnitParameterValue bwidth = mixer.eqBandwidth + 0.5;
        [self setCurveHeight:peak width:bwidth offset:center*2.0 - 0.5];
        [super render:w h:h];
    }
}
@end
