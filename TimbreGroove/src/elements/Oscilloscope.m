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

@interface OscilloscopeMesh : Geometry {
    float _spacing;
    float _width;
    float _height;
    float * _data;
}
@end

@implementation OscilloscopeMesh

- (id)initWithIndicesIntoNames:(NSArray *)indicesIntoNames
{
    self = [super init];
    if (self) {
        _spacing = kFramesForDisplay;
        _width = 2.0;
        _height = 2.0;
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
        *pos++ = _data ? _data[i] * _height : 0;
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
    float _data[kFramesForDisplay];
    __weak OscilloscopeMesh * _osc;
}

@end

@implementation Oscilloscope

-(void)createBuffer
{
    self.color = (GLKVector4){ 0.4, 1, 0.4, 1};
    OscilloscopeMesh * mesh = [[OscilloscopeMesh alloc] initWithIndicesIntoNames:@[@(gv_pos)]];
    _osc = mesh;
    [self addBuffer:mesh];
}

-(void)setSounds
{
    self.soundName = @"ambience";
    [self.sound playMidiFile:@"simpleMel"];
}

-(void)update:(NSTimeInterval)dt mixerUpdate:(MixerUpdate *)mixerUpdate
{
    AudioBufferList * abl = mixerUpdate->audioBufferList;
    if( abl )
    {
        [_osc resetScopeData:abl->mBuffers[0].mData];
        [_osc resetVertices];
    }
    Mixer * mixer = [Mixer sharedInstance];
    //mixer.selectedEQdBand ???
    float r = mixer.eqBandwidth;
    float g = mixer.eqCenter;;
    float b = mixer.eqPeak;
    self.color = (GLKVector4){ r, g, b, 1};
}

@end
