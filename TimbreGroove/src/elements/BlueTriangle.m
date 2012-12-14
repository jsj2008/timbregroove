//
//  BlueSquare.m
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "BlueTriangle.h"

#import "Vanilla.h"
#import "TGVertexBuffer.h"
#import "TGCamera.h"
#import "TGViewController.h"

@implementation BlueTriangle

-(BlueTriangle *)init
{
    if( (self = [super init]) )
    {
#define NUM_POINTS 3
        
        float v[NUM_POINTS*3] = {
            -1, -1, 0,
            0,   1, 0,
            1,  -1, 0
        };
        
        GLKVector4 blue = { 0.0f, 0.0f, 1.0f, 1.0f };
        self.shader = [[Vanilla alloc] initWithColor:blue.v andData:v numVectors:NUM_POINTS];
        [self addBuffer:[(Vanilla *)self.shader buffer]];        
    }
    
    return self;
}

-(void)update:(TGViewController *)vc
{
    static NSTimeInterval dt;
    
    dt += (vc.timeSinceLastUpdate * 50.0f);
    
    GLfloat r = GLKMathDegreesToRadians(dt);

    GLKVector3 rot = { 0, r, 0 };    
    self.rotation = rot;
}
@end
