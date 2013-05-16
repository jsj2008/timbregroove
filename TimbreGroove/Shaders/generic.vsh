//
//  Created by victor on 10/25/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
//
precision highp float;

attribute vec4 a_position;
uniform mat4 u_pvm;

#ifdef TEXTURE
attribute vec2 a_uv;
varying lowp vec2 v_texCoordOut;
#endif

#ifdef COLOR
attribute vec4 a_color;
varying vec4 v_vertex_color;
#endif

#ifdef BONES

uniform int  u_numJoints;
uniform mat4 u_jointMats[12];
uniform mat4 u_jointInvMats[12];

// ok, so this is not really a vec4, it's a variable array
// of floats and limits the number of influencing joints
// to 4 per pixel

attribute vec4 a_boneWeights;
attribute vec4 a_boneIndex;

vec4 doSkinning(mat4 pvm, vec4 inpos)
{
    if( u_numJoints == 0 )
        return pvm * inpos;
    
    vec4 pos = inpos;

    ivec4 index = ivec4(a_boneIndex);
    vec4  weights = a_boneWeights;
    
    for( int j = 0; j < 4; j++ )
    {
        float weight = weights[j];
        if( weight == 0.0 )
            break;

        pos += (((u_jointInvMats[index[j]] * vec4(inpos.xyz,1.0)) * u_jointMats[index[j]]) * weight);
    }

    return pvm * pos;
}
#endif

#ifdef NORMAL
attribute vec3 a_normal;

varying vec4 v_vertexPosition;
varying vec3 v_vertexNormal;
#endif


void main()
{
#ifdef TEXTURE
    v_texCoordOut = a_uv;
#endif
    
#ifdef COLOR
    v_vertex_color = a_color;
#endif
    
#ifdef NORMAL
    v_vertexPosition = a_position;
    v_vertexNormal = a_normal;
#endif
    
#ifdef BONES
    gl_Position = doSkinning(u_pvm, a_position);
#else
	gl_Position = u_pvm * a_position;
#endif

}

