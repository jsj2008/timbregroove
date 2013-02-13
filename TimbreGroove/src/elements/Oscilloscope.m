//
//  Oscilloscope.m
//  TimbreGroove
//
//  Created by victor on 2/12/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Oscilloscope.h"
#import "Geometry.h"
#import "Mixer.h"

#define NUM_POINTS 512
#define NUM_POINTS_F ((float)NUM_POINTS)

@interface OscilloscopeMesh : Geometry {
    float _spacing;
    float _width;
    float * _data;
}
@end

@implementation OscilloscopeMesh

- (id)initWithIndicesIntoNames:(NSArray *)indicesIntoNames
{
    self = [super init];
    if (self) {
        _spacing = NUM_POINTS_F;
        _width = 2.0;
        self.drawType = TG_LINE_STRIP; // TG_POINTS;
        self.usage = GL_DYNAMIC_DRAW;
        [self createWithIndicesIntoNames:indicesIntoNames
                                   doUVs:false
                               doNormals:false];        
    }
    return self;
}
-(void)getStats:(GeometryStats *)stats
{
    stats->numVertices = _spacing + 1;
    stats->numIndices  = 0;
}

-(void)resetScopeData:(float *)data
{
    _data = data;
}

-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
             withUVs:(bool)withUVs
         withNormals:(bool)withNormals
{
    unsigned int i;
    GLfloat x;
    
    float * pos = (float *)vertextData;
    float gridSize = _width / _spacing;
    for( i = 0; i < _spacing+1; i++ )
    {
        x = -(_width/2.0) + (gridSize * i);

        *pos++ = x;
        *pos++ = _data ? _data[i] : 0;
        *pos++ = 0;
        if( withNormals )
        {
            *pos++ = 0;
            *pos++ = 0;
            *pos++ = 1.0;
        }
    }

}

@end

@interface Oscilloscope () {
    float _data[NUM_POINTS];
}

@end

@implementation Oscilloscope

-(void)createBuffer
{
    self.color = (GLKVector4){ 0.4, 1, 0.4, 1};
    OscilloscopeMesh * mesh = [[OscilloscopeMesh alloc] initWithIndicesIntoNames:@[@(gv_pos)]];
    [self addBuffer:mesh];
}

-(void)setSounds
{
    self.soundName = @"ambience";
    [self.sound playMidiFile:@"simpleMel"];
}

#define DIVISOR ((float)0x5FFF)

-(void)update:(NSTimeInterval)dt mixerUpdate:(MixerUpdate *)mixerUpdate
{
    AudioBufferList * abl = mixerUpdate->audioBufferList;
    unsigned int numFrames = mixerUpdate->numFrames;
    
    AudioSampleType * pleft  = abl->mBuffers[0].mData;
    float prevs[4] = { 0, 0, 0, 0 };
    int ring = 0;
    for( int i = 0; i < numFrames; i++ )
    {
        float f = (float)( *pleft++ ) / DIVISOR;
        for (int n = 0; n < 4; n++ ) {
            int x = 3 - ((ring + n) % 4);
            f += prevs[ x ] / (float)((n+1)*5);
        }
        _data[i] = f;
        prevs[ring] = f;
        ring = (ring + 1) % 4;
    }
    [((OscilloscopeMesh *)_buffers[0]) resetScopeData:_data];
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    [_buffers[0] resetVertices];
    [super render:w h:h];
}
@end
