//
//  RainbowShader.vsh
//  created with Shaderific
//


attribute vec4 position;
attribute vec3 normal;

uniform mat4 modelViewProjectionMatrix;
uniform mat4 modelViewMatrix;
uniform mat3 normalMatrix;
uniform float time;

varying vec4 materialDiffuseColor;
varying vec3 eyespaceNormal; 
varying vec4 eyespacePosition;

const float M_PI = 3.14159;


void main(void)
{

    float r = length(position.xyz);
    float theta = asin(position.y / r);
    theta = theta / M_PI + 0.5;

    float phi = atan(position.z , position.x);
    phi = phi / M_PI / 2.0 + 0.5;
    
    float colorAngle;
   
    colorAngle = phi;
//    colorAngle = theta;
//    colorAngle = (theta + 2.0 * phi);
//    colorAngle = (theta + 2.0 * phi) + time / 10.0;
    
    highp float number = floor(colorAngle);
    if (number > 0.0)
        colorAngle = colorAngle - number;
    
    highp float H = colorAngle * 360.0;
    highp float S = 1.0;
    highp float V = 1.0;
    
    highp float h = floor(H / 60.0);
    highp float f = H / 60.0 - h;
    
    highp float p = V * (1.0 - S);
    highp float q = V * (1.0 - S * f);
    highp float t = V * (1.0 - S * (1.0 - f));
    
    highp vec4 color;
    
    if (h <= 0.0)
        color = vec4(V, t, p, 1.0);
    else if (h == 1.0)
        color = vec4(q, V, p, 1.0);
    else if (h == 2.0)
        color = vec4(p, V, t, 1.0);    
    else if (h == 3.0)
        color = vec4(p, q, V, 1.0);    
    else if (h == 4.0)
        color = vec4(t, p, V, 1.0);    
    else if (h == 5.0)
        color = vec4(V, p, q, 1.0); 
    else if (h == 6.0)
        color = vec4(V, t, p, 1.0); 


    materialDiffuseColor = color;
    eyespaceNormal = normalMatrix * normal;
    eyespacePosition = modelViewMatrix * position;
    gl_Position = modelViewProjectionMatrix * position;

}
