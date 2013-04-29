//
//  generic frag shader
//
//  Created by victor on 11/20/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
precision highp float;

uniform mat4 u_mvm;

#ifdef TEXTURE
uniform sampler2D u_sampler;
varying lowp vec2 v_texCoordOut;
#else
    #ifdef COLOR
        varying vec4 v_vertex_color;
    #endif
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

vec4 l_color;
vec4 l_specular;

uniform mat3   u_normalMat;
uniform int    u_lightsEnabled;
uniform Light  u_lights[NUM_LIGHTS];
uniform vec4   u_material[CI_NUM_COLORS];
uniform float  u_shininess;
uniform bool   u_doSpecular;

vec3 l_ecPosition3;
vec3 l_normal;
vec3 l_eye;

varying vec4 v_vertexPosition;
varying vec3 v_vertexNormal;

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
    
	// 1 means light source is spot
    // 0 means directional
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
        mat3 normalMat = u_normalMat;
        
        normalMat = mat3( u_mvm );
        
		l_ecPosition3  = vec3(u_mvm * v_vertexPosition);
		l_eye          = -normalize(l_ecPosition3);
		l_normal       = normalize( normalMat * v_vertexNormal );
        
        for( int i = 0; i < u_lightsEnabled; i++ )
            pointLight( u_lights[i], amb, diff, spec );
        
		l_color.rgb = (u_material[CI_Ambient].rgb + amb.rgb) * u_material[CI_Ambient].rgb +
        (diff.rgb * u_material[CI_Diffuse].rgb);
        
		l_color.a   = u_material[CI_Diffuse].a;
		
		l_color    = clamp(l_color, 0.0, 1.0);
		l_specular = vec4( spec.rgb * u_material[CI_Specular].rgb, u_material[CI_Specular].a );
        
	} else {
		l_color = u_material[CI_Diffuse];
		l_specular = spec;
	}
}


#endif

#ifdef TIME
varying float v_time;
#endif

#ifdef TEXTURE_DISTORT
uniform float u_rippleSize;
uniform vec2  u_ripplePt;

vec4 texture_dist()
{
    vec2  center     = u_ripplePt;
    float rippleSize = u_rippleSize;
    
    if( rippleSize < 0.1 )
        rippleSize = 0.2;
    
    vec2  pos       = (v_texCoordOut - 0.5) * 2.0; // transpose to object space
    vec2  position  = (pos - center);
    float length    = length(position);   // sqroot( x-sqr + y-sqr + z+sqr )
    vec2  direction = position / length;
    
    float t = v_time * 0.1;
    float ripple     = (length * (rippleSize*2.0)) - (t * rippleSize);
    vec2 diff = ((direction * cos(ripple))/100.0);
    /*
    float max = 0.15;
    float alpha = ((max - length(diff)) / max);
    */
    vec3 coord = texture2D(u_sampler, v_texCoordOut + diff).rgb;
    float alpha = clamp( sin(coord.x) * cos(coord.y) * 1.2, 0.0, 1.0 );
    return vec4( coord, alpha );
}
#endif

void main()
{
    vec4 color = vec4(0);
    
#ifdef TEXTURE
    #ifdef TEXTURE_DISTORT
        color = texture_dist();
    #else
        color = texture2D(u_sampler, v_texCoordOut);
    #endif
#else
    #ifdef COLOR
        color = v_vertex_color;
    #endif
#endif
    
#ifdef NORMAL
    doLighting();
    color += l_color;
    color = vec4(color.rgb + l_specular.rgb, color.a);
#endif
    
    gl_FragColor = color;
}
