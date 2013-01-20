//
//  FullScreenTexture.vsh
//  created with Shaderific
//


attribute vec4 position;
attribute vec2 texture;

varying vec2 textureCoordinate;


void main(void)
{

    textureCoordinate = texture;

    gl_Position = position;

}