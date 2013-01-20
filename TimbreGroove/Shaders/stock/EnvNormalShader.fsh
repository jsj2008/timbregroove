//
//  EnvNormalShader.fsh
//  created with Shaderific
//


varying mediump vec3 normalVarying;
varying mediump vec2 textureCoordinate;
varying highp vec4 eyespacePosition;

uniform mediump mat3 normalMatrix;
uniform highp vec4 materialSpecularColor;
uniform highp float materialSpecularExponent;
uniform highp vec4 lightPosition;

uniform samplerCube texture0;
uniform sampler2D texture1;


void main(void)
{
    
    mediump vec2 repetitions = vec2(10.0, 5.0);
    mediump vec3 materialSpecularColor = materialSpecularColor.xyz;
    
    highp float theta = acos(normalVarying.y); 
    highp float phi = atan(normalVarying.z, normalVarying.x);
    
    highp vec2 deltaNormal = (texture2D(texture1, textureCoordinate * repetitions).xy - 0.5);
    theta = theta + deltaNormal.y;
    phi = phi - deltaNormal.x;
    
    mediump vec3 normal = vec3(cos(phi) * sin(theta), cos(theta), sin(phi) * sin(theta));
    normal = normalMatrix * normal;

    mediump vec3 lightDirection = normalize(vec3(lightPosition));
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