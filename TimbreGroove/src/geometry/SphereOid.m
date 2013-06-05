//
//  GridPlane.m
//  TimbreGroove
//
//  Created by victor on 1/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "SphereOid.h"

#define DEFAULT_SPHERE_CHUNK 30

@interface SphereOid () {
    unsigned int _longs;
    unsigned int _lats;
    float _radius;
}

@end
@implementation SphereOid

+(id) sphereWithdIndicesIntoNames:(NSArray *)indicesIntoNames
{
    return [SphereOid sphereWithRadius:1
                              andLongs:DEFAULT_SPHERE_CHUNK
                               andLats:DEFAULT_SPHERE_CHUNK
                   andIndicesIntoNames:indicesIntoNames];
}

+(id) sphereWithRadius:(float)radius
              andLongs:(unsigned int)longs
               andLats:(unsigned int)lats
   andIndicesIntoNames:(NSArray *)indicesIntoNames
{
    SphereOid * sp = [SphereOid new];
    if( sp )
    {
        sp->_lats = lats;
        sp->_longs = longs;
        sp->_radius = radius;
        [sp createWithIndicesIntoNames:indicesIntoNames];
    }
  //  sp.drawType = GL_POINTS;
    return sp;
}

-(void)getStats:(GeometryStats *)stats
{
    stats->numVertices = ((_longs+1) * (_lats+1));
    stats->numIndices = _longs*_lats*6;
}

-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
{
    float * data = vertextData;
    bool wUV = self.UVs;
    bool wNormals = self.normals;
    
	for (int latNumber = 0; latNumber <= _lats; ++latNumber) {

        float theta = latNumber * M_PI / _lats;
        float sinTheta = sin(theta);
        float cosTheta = cos(theta);

		for (int longNumber = 0; longNumber <= _longs; ++longNumber) {
        
			float phi = longNumber * 2 * M_PI / _longs;
			
            float sinPhi = sin(phi);
			float cosPhi = cos(phi);
			
			float x = cosPhi * sinTheta;
			float y = cosTheta;
			float z = sinPhi * sinTheta;
            
            *data++ = _radius * x;
            *data++ = _radius * y;
            *data++ = _radius * z;
			         
            //printf("{ %.4f, %.4f, %.4f }\n", _radius * x, _radius * y, _radius * z);
            
            float u,v;
            if( wUV )
            {
                u = 1 - ((float)longNumber / (float)_longs);
                v = 1 - ((float)latNumber / (float)_lats);
                
                *data++ = u;
                *data++ = v;
                
            }

            if( wNormals )
            {
                *data++ = x;
                *data++ = y;
                *data++ = z;
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
