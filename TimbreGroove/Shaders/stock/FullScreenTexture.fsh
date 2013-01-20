//
//  FullScreenTexture.fsh
//  created with Shaderific
//


varying mediump vec2 textureCoordinate;

uniform sampler2D texture0;


void main(void)
{

    // Rotate the color components
    mediump vec3 color = texture2D(texture0, textureCoordinate).zxy; 
    
    gl_FragColor = vec4(color, 1.0);
    
}