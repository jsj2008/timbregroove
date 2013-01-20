//
//  VertexLighting.vsh
//  created with Shaderific
//

attribute vec4 position;
attribute vec3 normal;

varying lowp vec4 colorVarying;

uniform mat4 modelViewProjectionMatrix;
uniform mat4 modelViewMatrix;
uniform mat3 normalMatrix;

uniform vec4 materialAmbientColor;
uniform vec4 materialDiffuseColor0;
uniform vec4 materialSpecularColor;
uniform float materialSpecularExponent;

uniform vec4 lightPosition;

void main(void)
{

    vec3 materialAmbientColor = materialAmbientColor.xyz;
    vec3 materialDiffuseColor = materialDiffuseColor0.xyz;
    vec3 materialSpecularColor = materialSpecularColor.xyz;

    vec3 lightDirection;
    
    if (lightPosition.w == 0.0)
        lightDirection = normalize(vec3(lightPosition));
    else
        lightDirection = normalize(vec3(lightPosition - modelViewMatrix * position)); 

    vec3 eyespaceNormal = normalMatrix * normal; 
    vec3 viewDirection = vec3(0.0, 0.0, 1.0);
    vec3 halfPlane = normalize(lightDirection + viewDirection);

    float diffuseFactor = max(0.0, dot(eyespaceNormal, lightDirection)); 
    float specularFactor = max(0.0, dot(eyespaceNormal, halfPlane)); 

    specularFactor = pow(specularFactor, materialSpecularExponent);
    vec3 color = materialAmbientColor + diffuseFactor * materialDiffuseColor + specularFactor * materialSpecularColor;

    colorVarying = vec4(color, 1.0);
    
    gl_Position = modelViewProjectionMatrix * position;

}
