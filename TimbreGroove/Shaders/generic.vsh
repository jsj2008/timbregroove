//
//  Created by victor on 10/25/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
//
precision highp float;

attribute vec4 a_position;
uniform mat4 u_pvm;
uniform mat4 u_mvm;

#ifdef TEXTURE
attribute vec2 a_uv;
varying lowp vec2 v_texCoordOut;
#endif

#ifdef COLOR
attribute vec4 a_color;
varying vec4 v_vertex_color;
#endif

#ifdef BONES
attribute int   a_boneIndex;
attribute float a_boneWeights;
#endif

#ifdef NORMAL

#define NUM_LIGHTS 2

const int CI_Ambient  = 0;
const int CI_Diffuse  = 1;
const int CI_Specular = 2;
const int CI_Emission = 3;

const int CI_NUM_COLORS = 4;

struct Light {
	vec4   position;
    vec4   colors[CI_NUM_COLORS];
	vec3   attenuation;
    
	float spotCutoffAngle;
	vec3  spotDirection;
	float spotFalloffExponent;
};

attribute vec3 a_normal;

varying vec4   v_color;
varying vec4   v_specular;

uniform mat3   u_normalMat;
uniform int    u_lightsEnabled;
uniform Light  u_lights[NUM_LIGHTS];
uniform vec4   u_material[CI_NUM_COLORS];
uniform float  u_shininess;
uniform bool   u_doSpecular;

vec3 l_ecPosition3;
vec3 l_normal;
vec3 l_eye;
vec4 l_vertexPosition;
vec3 l_vertexNormal;


void pointLight(const in Light light,
				inout vec4 ambient,
				inout vec4 diffuse,
				inout vec4 specular)
{
	float nDotVP;
	float eDotRV;
	float pf;
	float attenuation;
	float d;
	vec3 VP;
	vec3 reflectVector;
    
	// 1 means light source is directional
    // 0 means ambient
	if (light.position.w == 0.0)
    {
		attenuation = 1.0;
		VP = light.position.xyz;
    }
    else
    {
        // Normalize the distance of the
		// Vector between light position and vertex
		VP = vec3(light.position.xyz - l_ecPosition3);
		d  = length(VP);
		VP = normalize(VP);

		// Calculate attenuation
		vec3 attDist = vec3(1.0, d, d * d);
		attenuation = 1.0 / dot(light.attenuation, attDist);
        
		// Calculate spot lighting effects
		if (light.spotCutoffAngle > 0.0) {
			float spotFactor = dot(-VP, light.spotDirection);
			if (spotFactor >= cos(radians(light.spotCutoffAngle))) {
				spotFactor = pow(spotFactor, light.spotFalloffExponent);
			} else {
				spotFactor = 0.0;
			}
			attenuation *= spotFactor;
		}
	}
    
	// angle between normal and light-vertex vector
	nDotVP = max(0.0, dot(VP, l_normal));
	
 	ambient += light.colors[CI_Ambient] * attenuation;
	if (nDotVP > 0.0) {
		diffuse += light.colors[CI_Diffuse] * (nDotVP * attenuation);
        
		if (u_doSpecular) {
			// reflected vector
			reflectVector = normalize(reflect(-VP, l_normal));
			
			// angle between eye and reflected vector
			eDotRV = max(0.0, dot(l_eye, reflectVector));
			eDotRV = pow(eDotRV, 16.0);
            
			pf = pow(eDotRV, u_shininess);
			specular += light.colors[CI_Specular] * (pf * attenuation);
		}
	}
}

void doLighting()
{
	vec4 amb = vec4(0.0);
	vec4 diff = vec4(0.0);
	vec4 spec = vec4(0.0);
    
	if( u_lightsEnabled > 0 )
    {
		l_ecPosition3  = vec3(u_mvm * l_vertexPosition);
		l_eye          = -normalize(l_ecPosition3);
		l_normal       = normalize( u_normalMat * l_vertexNormal );
        
        for( int i = 0; i < u_lightsEnabled; i++ )
        {
            if( u_lights[i].enabled )
                pointLight( u_lights[i], amb, diff, spec );
        }
        
		v_color.rgb = u_material[CI_Ambient].rgb + (diff.rgb * u_material[CI_Diffuse].rgb);
		v_color.a   = u_material[CI_Diffuse].a;
		
		v_color    = clamp(v_color, 0.0, 1.0);
		v_specular = vec4( spec.rgb * u_material[CI_Specular].rgb, u_material[CI_Specular].a );
		
	} else {
		v_color = u_material[CI_Diffuse];
		v_specular = spec;
	}
}

#endif

#ifdef TIME
uniform float u_time;
varying float v_time;
#endif

void main()
{
    vec3 pos = a_position.xyz;

#ifdef TEXTURE
    v_texCoordOut = a_uv;
#endif
    
#ifdef COLOR
    v_vertex_color = a_color;
#endif
    
    
#ifdef TIME
    v_time = u_time;
#endif

	gl_Position = u_pvm * vec4(pos,a_position.w);
}

