//
//  NoteGenerator.h
//  TimbreGroove
//
//  Created by victor on 3/8/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _Scales {
    kScaleDiatonic,
    kScalePentatonic,
    kScaleMinor,
    kScaleSemitones,
    kScaleBluesPen,
    kScaleCustom
} Scales;

typedef struct _NoteRange {
    int low;
    int high;
} NoteRange;

@interface NoteGenerator : NSObject

-(id) initWithScale:(Scales)scale isRandom:(bool)random;
-(id) initWithScale:(Scales)scale isRandom:(bool)random andRange:(NoteRange)range;
-(id) initWithCustomScale:(int *)intervals numNotes:(int)numNotes;

-(int)next;

@property (nonatomic) bool      random;
@property (nonatomic) NoteRange range;
@property (nonatomic) Scales    scale;
@end
