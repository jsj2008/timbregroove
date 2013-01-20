//
//  TileShader.vsh
//  created with Shaderific
//


attribute vec4 position;
attribute vec3 normal;
attribute vec2 texture;

uniform mat4 modelViewProjectionMatrix;

varying vec3 normalVarying; 
varying vec2 textureCoordinate;


void main(void)
{

    normalVarying =  normal;
    textureCoordinate = texture;
    gl_Position = modelViewProjectionMatrix * position;

}