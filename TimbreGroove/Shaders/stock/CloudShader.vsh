//
//  CloudShader.vsh
//  created with Shaderific
//


attribute vec4 position;
attribute vec3 normal;

uniform mat4 modelViewProjectionMatrix;
uniform mat4 modelViewMatrix;
uniform mat3 normalMatrix;

uniform float time;

varying vec3 eyespaceNormal; 
varying vec4 eyespacePosition;
varying vec3 noiseVector;


void main(void)
{
    
    vec3 translation = vec3(1.0, 1.0, 1.0) * time / 20.0;
    noiseVector = position.xyz + translation;
    
    eyespaceNormal = normalMatrix * normal;
    eyespacePosition = modelViewMatrix * position;
    gl_Position = modelViewProjectionMatrix * position;
    
}