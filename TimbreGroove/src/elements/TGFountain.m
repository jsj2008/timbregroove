//
//  TGFountain.m
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TG.h"
#import "TGElement.h"
#import "TGFountain.h"
#import "isgl3d.h"

#define ELLIPSE_POS_INC   0.02f // step increment for ellipse segment
//
// Top of ellipse is 0
// Circumference is 2 * M_PI
//
// M_PI_2 is PI/2 which is 1/4 around the ellipse
//
// Start arc at 9 o'clock
// End at (about) 2 o'clock
//
#define ELLIPSE_RESET         (0.0f)
#define ELLIPSE_CIRCUMFERENCE (2.0f * M_PI)
#define ELLIPSE_START_POS     (M_PI_2 * 3.0f)
#define ELLIPSE_END_POS       (M_PI_2 * 0.666666f)

#define ELLIPSE_MIN_WIDTH  (0.1f)
#define ELLIPSE_MAX_WIDTH  (0.4f)
#define ELLIPSE_MIN_HEIGHT (0.2f)
#define ELLIPSE_MAX_HEIGHT (0.8f)

#define ELLIPSE_POS_MIN_X (-0.5f)
#define ELLIPSE_POS_MAX_X (0.7f)
#define ELLIPSE_POS_MIN_Y (-0.3f)
#define ELLIPSE_POS_MAX_Y (0.3f)

#define NUM_POINTS 100

@interface TGFountainMesh : Isgl3dPrimitive

@end

@implementation TGFountainMesh

- (void) fillVertexData:(Isgl3dFloatArray *)vertexData
             andIndices:(Isgl3dUShortArray *)indices
{
    
    int i,p = 0;
    for( i = 0; i < NUM_POINTS; i++ )
    {
        [vertexData add:randomf(ELLIPSE_POS_MIN_X, ELLIPSE_POS_MAX_X)];
        [vertexData add:randomf(ELLIPSE_POS_MIN_Y, ELLIPSE_POS_MAX_Y)];
        [vertexData add:0.0];
        
        [vertexData add:0.0];
        [vertexData add:0.0];
        [vertexData add:1.0];
        
        [vertexData add:uXY];
        [vertexData add:vXY];
        
        //			Isgl3dLog(Info, @"x = %f y = %f u = %f v = % f", x, y, uXY, vXY);
    }
	
	for (int i = 0; i <= _nx; i++) {
		float x = -(_width / 2) + i * (_width / _nx);
		iRatio = (float)i / _nx;
		uX = _uvMap.uA + iRatio * uABVector;
		vX = _uvMap.vA + iRatio * vABVector;
        
		for (int j = 0; j <= _ny; j++) {
			float y = -(_height / 2) + j * (_height / _ny);
			jRatio = 1. - (float)j / _ny;
			uXY = uX + jRatio * uACVector;
			vXY = vX + jRatio * vACVector;
            
			[vertexData add:x];
			[vertexData add:y];
			[vertexData add:0.0];
			
			[vertexData add:0.0];
			[vertexData add:0.0];
			[vertexData add:1.0];
            
			[vertexData add:uXY];
			[vertexData add:vXY];
			
            //			Isgl3dLog(Info, @"x = %f y = %f u = %f v = % f", x, y, uXY, vXY);
		}
	}
	
	for (int i = 0; i < _nx; i++) {
		for (int j = 0; j < _ny; j++) {
			
			int first = i * (_ny + 1) + j;
			int second = first + (_ny + 1);
			int third = first + 1;
			int fourth = second + 1;
			
			[indices add:first];
			[indices add:second];
			[indices add:third];
            
			[indices add:third];
			[indices add:second];
			[indices add:fourth];
		}
	}
    
}

- (unsigned int) estimatedVertexSize {
	return NUM_POINTS * 8;
}

- (unsigned int) estimatedIndicesSize {
	return NUM_POINTS * 6;
}

@end

@interface TGFountain : TGElement
- (void)start
{
    [super start];
    
    [self.view.camera setPosition:iv3(0, 3, 7)];
}
- (void)tick:(float)dt
{
    Isgl3dNode * n = self.node;
    if(n)
    {

    }
}

@end

@implementation TGFountain

@end

@interface TGFountainFactory : NSObject
@end

@implementation TGFountainFactory
-(void)invoke
{
    TGFountain * st = [[TGFountain alloc] init];
    [st start];
}
@end