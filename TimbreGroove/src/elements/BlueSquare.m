//
//  BlueSquare.m
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "BlueSquare.h"

#import "Vanilla.h"
#import "TGVertexBuffer.h"

@implementation BlueSquare

-(BlueSquare *)init
{
    if( (self = [super init]) )
    {
#define NUM_POINTS 3
#define HALF_WIDTH 0.5f
        
        float v[NUM_POINTS*3] = {
            1,  -1, 0,
            0,   1, 0,
            -1, -1, 0
            
            /*
             HALF_WIDTH, -HALF_WIDTH, -HALF_WIDTH,
            -HALF_WIDTH, -HALF_WIDTH, -HALF_WIDTH,
             HALF_WIDTH,  HALF_WIDTH, -HALF_WIDTH,
             HALF_WIDTH,  HALF_WIDTH, -HALF_WIDTH,
            -HALF_WIDTH, -HALF_WIDTH, -HALF_WIDTH,
            -HALF_WIDTH,  HALF_WIDTH, -HALF_WIDTH,
            
            HALF_WIDTH, HALF_WIDTH, -HALF_WIDTH,
            -HALF_WIDTH, HALF_WIDTH, -HALF_WIDTH,
            HALF_WIDTH, HALF_WIDTH, HALF_WIDTH,
            HALF_WIDTH, HALF_WIDTH, HALF_WIDTH,
            -HALF_WIDTH, HALF_WIDTH, -HALF_WIDTH,
            -HALF_WIDTH, HALF_WIDTH, HALF_WIDTH, 
            
            HALF_WIDTH, HALF_WIDTH, 1,
            -HALF_WIDTH, HALF_WIDTH, 1,
            HALF_WIDTH, -HALF_WIDTH, 1,
            HALF_WIDTH, -HALF_WIDTH, 1,
            -HALF_WIDTH, HALF_WIDTH, 1,
            -HALF_WIDTH, -HALF_WIDTH, 1
             */
            
        };
        
        GLKVector4 blue = { 0.0f, 0.0f, 1.0f, 1.0f };
        self.shader = [[Vanilla alloc] initWithColor:blue.v andData:v numVectors:NUM_POINTS];
        [self addBuffer:[(Vanilla *)self.shader buffer]];        
    }
    
    return self;
}

@end
