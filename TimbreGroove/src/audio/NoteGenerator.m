//
//  NoteGenerator.m
//  TimbreGroove
//
//  Created by victor on 3/8/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "NoteGenerator.h"
#import "TGTypes.h"

@interface NoteGenerator () {
    Byte * _notes;
    int _numNotes;
    int _counter;
}

@end
@implementation NoteGenerator

-(id) initWithScale:(Scales)scale isRandom:(bool)random
{
    return [self initWithScale:scale isRandom:random andRange:(NoteRange){ 0, 127 }];
}

-(id) initWithScale:(Scales)scale isRandom:(bool)random andRange:(NoteRange)range
{
    self = [super init];
    if( self )
    {
        _scale = scale;
        _random = random;
        self.range = range;
    }
    return self;
    
}

-(id) initWithCustomScale:(int *)notes numNotes:(int)numNotes
{
    self = [super init];
    if( self )
    {
        _notes = malloc( numNotes * sizeof(*_notes));
        memcpy(_notes, notes, numNotes * sizeof(*_notes));
        _numNotes = numNotes;
        _scale = kScaleCustom;
        self.range = (NoteRange){0,127};
    }
    return self;
    
}

-(void)dealloc
{
    free(_notes);
}

-(void)setRange:(NoteRange)range
{
    _range = range;
    _numNotes = range.high - range.low + 1;
    if( _scale != kScaleCustom )
    {
        /*
         kScaleDiatonic,
         kScalePentatonic,
         kScaleMinor,
         kScaleSemitones,
         */
        
        static Byte diatonic[]   = { 2, 2, 1, 2, 2, 2, 1 };
        static Byte pentatonic[] = { 3, 2, 2, 3, 2 };
        static Byte minor[]      = { 2, 1, 2, 2, 1, 2, 1 };
        static Byte semitones[]  = { 1 };
        static Byte bluespen[]   = { 3, 2, 1, 1, 3, 1, 1 };
        static Byte * known[] = { diatonic, pentatonic, minor, semitones, bluespen };
        static int counts[]  = { 7,        5,          7,     1,          7        };
        
        Byte * intervals = known[_scale];
        int numIntervals  = counts[_scale];
        
        if( _notes )
            free(_notes);
        
        _notes = malloc( sizeof(Byte) * _numNotes );
        Byte nextNote = _range.low;
        int i;
        for( i = 0; i < _numNotes && nextNote <= _range.high; i++ )
        {
            _notes[i] = nextNote;
            nextNote += intervals[ i % numIntervals ];
        }
        _numNotes = i;
        _notes = realloc( _notes, sizeof(_notes[0]) * _numNotes );
    }
}

-(int)next
{
    int n = _random ? R0_n(_numNotes) : _counter++ % _numNotes;
    return _notes[n];
}

@end
