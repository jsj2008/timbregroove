//
//  LiquidShader.vsh
//  created with Shaderific
//


attribute vec4 position;
attribute vec3 normal;

uniform mat4 modelViewProjectionMatrix;
uniform mat4 modelViewMatrix;

varying vec3 normalVarying; 
varying vec4 eyespacePosition;
varying vec3 objectspacePosition;


void main(void)
{
    
    objectspacePosition = position.xyz;
    normalVarying =  normal;
    eyespacePosition = modelViewMatrix * position;
    
    gl_Position = modelViewProjectionMatrix * position;
    
}