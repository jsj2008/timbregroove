//
//  EnvironmentMapping.fsh
//  created with Shaderific
//


varying mediump vec3 eyespaceNormal;
varying highp vec4 eyespacePosition;

uniform highp vec4 materialSpecularColor;
uniform highp float materialSpecularExponent;
uniform highp vec4 lightPosition;

uniform samplerCube texture0;


void main(void)
{
    
    highp vec3 materialSpecularColor = materialSpecularColor.xyz;
    
    highp vec3 lightDirection; 
    
    if (lightPosition.w == 0.0)
        lightDirection = normalize(vec3(lightPosition));
    else
        lightDirection = normalize(vec3(lightPosition - eyespacePosition)); 
    
    highp vec3 normal = normalize(eyespaceNormal);
    highp vec3 viewDirection = vec3(0.0, 0.0, 1.0);
    highp vec3 halfPlane = normalize(lightDirection + viewDirection);
    
    highp float diffuseFactor = max(0.0, dot(normal, lightDirection)); 
    highp float specularFactor = max(0.0, dot(normal, halfPlane)); 
    
    highp vec3 reflection = eyespacePosition.xyz - 2.0 * dot(eyespacePosition.xyz, normal) * normal;
    highp vec3 materialDiffuseColor = textureCube(texture0, reflection).xyz;
    
    
    specularFactor = pow(specularFactor, materialSpecularExponent);
    highp vec3 color = diffuseFactor * materialDiffuseColor + specularFactor * materialSpecularColor;
    
    
    gl_FragColor = vec4(color, 1); 
    
}