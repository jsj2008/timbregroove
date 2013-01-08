//
//  Created by victor on 10/25/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
// Raise a 'hump' in a flat plane
//

attribute vec3 a_position;    // vertex array maps here
attribute vec2 a_texCoord0;  // uv array maps here

varying lowp vec2 v_TexCoordOut;

uniform mat4  u_viewprojMatrix;
uniform float u_humpDimension;
uniform vec3  u_apex;

bool isVectorInDistortionField( vec3 pos, float q, vec3 center )
{
    bool inRange = false;
    
    //if( inRange )
    {
        if( pos.x < center.x + q )
        {
            if( pos.x > center.x - q )
            {
                if( pos.y > center.y  )
                {
                    if( pos.y < center.y + q )
                    {
                        // upper left quad
                        inRange = true;
                    }
                }
                else
                {
                    if( pos.y > center.y - q )
                    {
                        // lower left quad
                        inRange = true;
                    }
                }
            }
        }
        else
        {
            if( pos.x < center.x + q )
            {
                if( pos.y > center.y )
                {
                    if( pos.y < center.y + q )
                    {
                        // upper right
                        inRange = true;
                    }
                }
                else
                {
                    if( pos.y > center.y - q )
                    {
                        // lower right
                        inRange = true;
                    }
                }
            }
        }
    }
    
    return inRange;
}

float smallestDistanceFromVariableEdge( vec3 pos, float q, vec3 center )
{
    float distances[4];
    
    distances[0] = abs( distance( pos, vec3( pos.x,         q + center.y,  0 ) ) );
    distances[1] = abs( distance( pos, vec3( q + center.x,  pos.y,         0 ) ) );
    distances[2] = abs( distance( pos, vec3( pos.x,         center.y - q,  0 ) ) );
    distances[3] = abs( distance( pos, vec3( center.x - q,  pos.y,         0 ) ) );
    
    float smallest = 100000.0;
    int i;
    for( i = 0; i < 4; i++ )
    {
        if( distances[i] < smallest )
        smallest = distances[i];
    }
    
    return smallest;
    
}

void main() {

    /*
     This creates a pyramid (from Zach):
     
     Let Q be the center of the square base.
     Let P be the desired position of the point (apex)
     Define a vector R=P-Q.
     
     Take a point X on the square base
     (X is a position vector, probably looks like (x,0,z) ).
     
     Now, for the four edges of the base, X is some distance
     d1, d2, d3,d4 from the corresponding edge.
     Let dmin be the minimum of these.
     
     Let w be half the width of the square.
     
     X + ( dmin/w * R ) is your answer.
     
     */
    vec3  Q = vec3(u_apex.xy, 0.0);
    vec3  X = a_position.xyz;
    float w = u_humpDimension / 2.0;
    
    if( isVectorInDistortionField( X, w, Q ) )
    {
        vec3 P = u_apex;
        vec3 R = P - Q;
        float dmin = smallestDistanceFromVariableEdge( X, w, Q );
        
        X = X + ((dmin / w) * R);
        X.z = (P.z * smoothstep( 0.0, P.z, X.z ));
        
    }
    
    v_TexCoordOut = a_texCoord0;
	gl_Position = u_viewprojMatrix * vec4(X,1.0);
}

