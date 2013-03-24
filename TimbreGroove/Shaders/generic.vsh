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
    float dist = sin(distance(pos,u_distortionPoint));
    pos += vec3(dist,dist,0) * u_distortionFactor;
    gl_Position = u_pvm * vec4( pos, a_position.w );
     */
    /*
    float length = distance(u_distortionPoint,pos.xyz);
    pos.x *= 1.0 + length/2.0;
    pos.y += length/2.0;
     */
    vec3 jointPt = vec3(1.0,0.0,0.0);
    if( abs(distance(pos,jointPt)) < 0.3 )
    {        
        float distToDistPt = distance(pos,u_distortionPoint);
        pos += distToDistPt * u_distortionFactor;
    }
    
    gl_Position = u_pvm * vec4(pos,a_position.w);
#else
	gl_Position   = u_pvm * vec4(pos,a_position.w);
#endif

}

