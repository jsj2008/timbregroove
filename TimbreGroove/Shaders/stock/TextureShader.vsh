//
//  TextureShader.vsh
//  created with Shaderific
//


attribute vec4 position;
attribute vec3 normal;
attribute vec2 texture;

uniform mat4 modelViewProjectionMatrix;
uniform mat4 modelViewMatrix;
uniform mat3 normalMatrix;

varying vec3 eyespaceNormal; 
varying vec4 eyespacePosition;
varying vec3 objectspacePosition;


void main(void)
{

    objectspacePosition = position.xyz;

    eyespaceNormal = normalMatrix * normal;
    eyespacePosition = modelViewMatrix * position;
    gl_Position = modelViewProjectionMatrix * position;

}