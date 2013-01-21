//
//  GridPlane.m
//  TimbreGroove
//
//  Created by victor on 1/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "SphereOid.h"

@interface SphereOid () {
    unsigned int _longs;
    unsigned int _lats;
    float _radius;
}

@end
@implementation SphereOid

+(id) sphereWithdIndicesIntoNames:(NSArray *)indicesIntoNames
                         andDoUVs:(bool)UVs
                     andDoNormals:(bool)normals
{
    return [SphereOid sphereWithRadius:1 andLongs:30 andLats:30
                   andIndicesIntoNames:indicesIntoNames
                              andDoUVs:UVs andDoNormals:normals];
}

+(id) sphereWithRadius:(float)radius
              andLongs:(unsigned int)longs
               andLats:(unsigned int)lats
   andIndicesIntoNames:(NSArray *)indicesIntoNames
              andDoUVs:(bool)UVs
          andDoNormals:(bool)normals
{
    SphereOid * sp = [SphereOid new];
    if( sp )
    {
        sp->_lats = lats;
        sp->_longs = longs;
        sp->_radius = radius;
        [sp createWithIndicesIntoNames:indicesIntoNames doUVs:UVs doNormals:normals];
    }
    return sp;
}

-(void)getStats:(GeometryStats *)stats
{
    stats->numVertices = ((_longs+1) * (_lats+1));
    stats->numIndices = _longs*_lats*6;
}

-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
             withUVs:(bool)wUV
         withNormals:(bool)wNormals
{
    float * data = vertextData;
    
	for (int latNumber = 0; latNumber <= _lats; ++latNumber) {
		for (int longNumber = 0; longNumber <= _longs; ++longNumber) {
            
			float theta = latNumber * M_PI / _lats;
			float phi = longNumber * 2 * M_PI / _longs;
			
			float sinTheta = sin(theta);
			float sinPhi = sin(phi);
			float cosTheta = cos(theta);
			float cosPhi = cos(phi);
			
			float x = cosPhi * sinTheta;
			float y = cosTheta;
			float z = sinPhi * sinTheta;
            
            *data++ = _radius * x;
            *data++ = _radius * y;
            *data++ = _radius * z;
			
            if( wNormals )
            {
                *data++ = x;
                *data++ = y;
                *data++ = z;
            }
            
            if( wUV )
            {
                float u = 1.0 - (1.0 * longNumber / _longs);
                float v = 1.0 * latNumber / _lats;
                *data++ = u;
                *data++ = v;
            }
		}
	}
    
    unsigned int * idata = indexData;
    
	for (int latNumber = 0; latNumber < _lats; latNumber++) {
		for (int longNumber = 0; longNumber < _longs; longNumber++) {
			
			int first = (latNumber * (_longs + 1)) + longNumber;
			int second = first + (_longs + 1);
			int third = first + 1;
			int fourth = second + 1;
			
            *idata++ = first;
            *idata++ = third;
            *idata++ = second;
            
            *idata++ = second;
            *idata++ = third;
            *idata++ = fourth;
		}
	}
    
}

@end
