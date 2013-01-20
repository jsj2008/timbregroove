//
//  RainbowShader.fsh
//  created with Shaderific
//


varying mediump vec4 materialDiffuseColor;
varying mediump vec3 eyespaceNormal;
varying highp vec4 eyespacePosition;

uniform highp vec4 materialSpecularColor;
uniform highp float materialSpecularExponent;
uniform highp vec4 lightPosition;

void main()
{

    highp vec3 lightDirection;; 
    
    if (lightPosition.w == 0.0)
        lightDirection = normalize(vec3(lightPosition));
    else
        lightDirection = normalize(vec3(lightPosition - eyespacePosition)); 
    
    highp vec3 normal = normalize(eyespaceNormal);
    highp vec3 viewDirection = vec3(0.0, 0.0, 1.0);
    highp vec3 halfPlane = normalize(lightDirection + viewDirection);
    
    highp float diffuseFactor = max(0.0, dot(normal, lightDirection)); 
    highp float specularFactor = max(0.0, dot(normal, halfPlane)); 
    
    specularFactor = pow(specularFactor, materialSpecularExponent);
                 
    gl_FragColor =  diffuseFactor * materialDiffuseColor + specularFactor * materialSpecularColor;

}