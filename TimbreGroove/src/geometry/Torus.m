//
//  Torus.m
//  TimbreGroove
//
//  Created by victor on 1/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Torus.h"

@interface Torus() {
    float _radius;
    float _tubeRadius;
    unsigned int _nt;
    unsigned int _ns;
}

@end
@implementation Torus

+(id) torusWithIndicesIntoNames:(NSArray *)indicesIntoNames
                        andDoUVs:(bool)UVs
                    andDoNormals:(bool)normals
{
    return [Torus torusWithRadius:1.0 andTubeRadius:0.5f andGridStop:20
              andIndicesIntoNames:indicesIntoNames andDoUVs:UVs andDoNormals:normals];
}

+(id) torusWithRadius:(float)radius
        andTubeRadius:(float)tubeRadius
          andGridStop:(unsigned int)gridStop
  andIndicesIntoNames:(NSArray *)indicesIntoNames
             andDoUVs:(bool)UVs
         andDoNormals:(bool)normals
{
    Torus * torus = [Torus new];
    if( torus )
    {
        torus->_nt = torus->_ns = gridStop;
        torus->_radius = radius;
        torus->_tubeRadius = tubeRadius;
        [torus createWithIndicesIntoNames:indicesIntoNames doUVs:UVs doNormals:normals];
    }
    
    return torus;
}

-(void)getStats:(GeometryStats *)stats
{
    stats->numVertices = (_nt + 1) * (_ns + 1) * 8;
    stats->numIndices = _nt * _ns * 6;
}

-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
             withUVs:(bool)wUV
         withNormals:(bool)wNormals
{
    float * pos = (float *)vertextData;
    
	for (int s = 0; s <= _ns; s++) {
		float theta = s * 2 * M_PI / _ns;
		for (int t = 0; t <= _nt; t++) {
			float phi = t * 2 * M_PI / _nt;
			
			float sinTheta = sin(theta);
			float sinPhi = sin(phi);
			float cosTheta = cos(theta);
			float cosPhi = cos(phi);
			
			float x = sinTheta * (_radius + _tubeRadius * sinPhi);
			float y =                     - _tubeRadius * cosPhi;
			float z = cosTheta * (_radius + _tubeRadius * sinPhi);
            
			*pos++ = x;
			*pos++ = y;
			*pos++ = z;

            if( wUV )
            {
                float u = 1.0 * s / _ns;
                float v = 1.0 - (1.0 * t / _nt);
                *pos++ = u;
                *pos++ = v;
            }

            if( wNormals )
            {
                float nx = sinTheta * sinPhi;
                float ny = -cosPhi;
                float nz = cosTheta * sinPhi;
                *pos++ = nx;
                *pos++ = ny;
                *pos++ = nz;
            }
		}
	}
    
    unsigned int * pi = indexData;
    
	for (int s = 0; s < _ns; s++) {
		for (int t = 0; t < _nt; t++) {
			
			int first = (s * (_nt + 1)) + t;
			int second = first + (_nt + 1);
			int third = first + 1;
			int fourth = second + 1;
			
            *pi++ = first;
            *pi++ = second;
            *pi++ = third;

            *pi++ = second;
            *pi++ = fourth;
            *pi++ = third;
		}
	}
}
@end
