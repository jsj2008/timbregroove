//
//  BrickShader.vsh
//  created with Shaderific
//
//  Vertex shader for procedural bricks
//
//  Authors: Dave Baldwin, Steve Koren, Randi Rost
//          based on a shader by Darwyn Peachey
//
//  Copyright (c) 2002-2006 3Dlabs Inc. Ltd. 
//
//  See the file menu for license information
//

attribute vec4 position;
attribute vec3 normal;

uniform mat4 modelViewProjectionMatrix;
uniform mat4 modelViewMatrix;
uniform mat3 normalMatrix;
uniform vec4 lightPosition;

const float SpecularContribution = 0.3;
const float DiffuseContribution  = 1.0 - SpecularContribution;

varying float LightIntensity;
// varying vec2  MCposition;
varying vec3 objectspacePosition;

const float pi = 3.14159;

void main() 
{

    float w = lightPosition.w;
    vec3 lightPosition = lightPosition.xyz;

	vec3 ecPosition = (modelViewMatrix * position).xyz;
	vec3 tnorm      = normalMatrix * normal;
    vec3 lightVec;
    
    if (w == 0.0)
        lightVec = normalize(lightPosition);
    else
       lightVec = normalize(lightPosition - ecPosition); 

	vec3 reflectVec = reflect(-lightVec, tnorm);	
	vec3 viewVec    = normalize(-ecPosition);
	float diffuse   = max(dot(lightVec, tnorm), 0.0);
	float spec      = 0.0;

	if (diffuse > 0.0) {
		spec = dot(reflectVec, viewVec);
		spec = pow(spec, 16.0);
	}

	LightIntensity = DiffuseContribution * diffuse + 
				   SpecularContribution * spec;

//    float r = length(position.xyz);
//    float theta = asin(position.y / r);
//    float phi = atan(position.z , position.x);
//
//    
//	MCposition  = vec2(phi, theta);  
    
    objectspacePosition = position.xyz;
	gl_Position = modelViewProjectionMatrix * position;

}