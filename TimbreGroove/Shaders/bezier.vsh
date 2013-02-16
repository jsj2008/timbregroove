//
//  Created by victor on 10/25/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
//
precision highp float;

attribute float a_t_spacing;

uniform mat4  u_pvm;
uniform vec3  u_controlPoints[5];


void main()
{
// yes, someday these will passed in from code
// like, when that's needed
float coefficients[5];
coefficients[0]=1.0;
coefficients[1]=4.0;
coefficients[2]=6.0;
coefficients[3]=4.0;
coefficients[4]=1.0;

    vec4 vt = vec4( vec3(0), 1.0 );
    int j;
    float t = a_t_spacing, factor;
    for (j=0; j<5; j++)
    {
        float jf = float(j);
        factor = pow(t, jf) *
                 pow(1.0-t, 5.0-jf-1.0) *
                 coefficients[j];
        vt.x += factor * u_controlPoints[j].x;
        vt.y += factor * u_controlPoints[j].y;
        vt.z += factor * u_controlPoints[j].z;
    }

    //vt = vec4(a_t_spacing,0,0,1);
    gl_Position =  u_pvm * vt;
}

