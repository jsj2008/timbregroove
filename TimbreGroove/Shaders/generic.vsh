//
//  Created by victor on 10/25/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
//
precision highp float;

attribute vec4 a_position;

#ifdef TEXTURE
attribute vec2 a_uv;
varying lowp vec2 v_texCoordOut;
#endif

#ifdef COLOR
attribute vec4 a_color;
varying vec4 v_color;
#endif

#ifdef NORMAL
attribute vec3 a_normal;

uniform mat3 u_normalMat;
uniform vec3 u_lightDir;
uniform vec3 u_dirColor;
uniform vec3 u_ambient;
varying vec3 v_lightFilter;
#endif

#ifdef MESH_DISTORT
uniform vec3 u_distortionPoint;
uniform float u_distortionFactor;
vec3 distortForPt( vec3 V, vec3 M )
{
    float range = 0.4;

    float range2 = range * range;
    vec3 MV = V - M;
    float alpha = range2 / (range2 + dot(MV, MV));
    return alpha * M + (1.0-alpha) * V;
}
#endif

#ifdef TIME
uniform float u_time;
varying float v_time;
#endif

uniform mat4 u_pvm;

void main()
{
    vec3 pos = a_position.xyz;

#ifdef TEXTURE
    v_texCoordOut = a_uv;
#endif
    
#ifdef COLOR
    v_color = a_color;
#endif
    
#ifdef NORMAL
    vec3 transformedNormal = u_normalMat * a_normal;
    float directionalLightWeighting = max(dot(transformedNormal, u_lightDir), 0.0);
    v_lightFilter = u_ambient + u_dirColor * directionalLightWeighting;
#endif
    
#ifdef TIME
    v_time = u_time;
#endif

#ifdef MESH_DISTORT
    /*
     point V =     [incoming vertex]
     point M =     [magnet location]
     float range = [chosen nominal range for the magnetic effect]
     
     float range2 = range * range  [range squared, for comparison with squared distance]
     vector MV = V - M             [vector from M to V]
     float alpha = range2 / (range2 + dot(MV, MV))  [weighting factor]
     point V' =  alpha * M + (1-alpha) * V          [new, "magnetized" position]
    */

    pos = distortForPt(pos,vec3(2.0,0.0,0.0));
    pos = distortForPt(pos,vec3(2.0,1.0,0.0));

    gl_Position = u_pvm * vec4(pos,a_position.w);
#else
	gl_Position   = u_pvm * vec4(pos,a_position.w);
#endif

}

